require "test_helper"
require_relative "../support/booking_data"

class OperateBookingTest < ActiveSupport::TestCase
  include BookingData

  def create_booking(overrides = {})
    Booking.create!(booking_attributes(booking_date: Date.current).merge(overrides))
  end

  def operation(booking, action = "checkin", **options)
    OperateBooking.new(booking_id: booking.id, action: action, lock_version: booking.lock_version, **options)
  end

  test "checkin at start uses server time and records operational audit without personal fields" do
    travel_to Time.zone.local(2026, 11, 25, 8) do
      booking = create_booking
      assert_difference "AuditEvent.count", 1 do
        assert operation(booking).call
      end
      booking.reload
      assert_equal "em_operacao", booking.status
      assert_equal Time.current, booking.checkin_at
      assert_nil booking.released_at
      assert_equal 1, booking.lock_version
      event = AuditEvent.find_by!(entity_id: booking.id, action: "checkin")
      assert_equal "agendado", event.previous_values["status"]
      assert_nil event.previous_values["checkin_at"]
      assert_equal "em_operacao", event.new_values["status"]
      assert_equal Time.current, Time.iso8601(event.new_values.fetch("checkin_at"))
      assert_empty event.new_values.keys & %w[contact_name company invoice plate vehicle_model request_id]
    end
  end

  test "checkin boundaries and late arrivals follow server time without imposing an end of window cutoff" do
    [ [ 7, 59, 59, false ], [ 8, 0, 0, true ], [ 11, 20, 0, true ], [ 17, 29, 59, true ], [ 17, 30, 0, false ], [ 17, 48, 0, false ], [ 18, 0, 0, false ] ].each do |hour, minute, second, allowed|
      travel_to Time.zone.local(2026, 11, 25, hour, minute, second) do
        booking = create_booking(dock_number: 8)
        op = operation(booking)
        assert_equal allowed, op.call, "#{hour}:#{minute}:#{second}"
        assert_equal allowed ? "em_operacao" : "agendado", booking.reload.status
        assert_equal allowed ? 1 : 0, AuditEvent.where(entity_id: booking.id).count
        booking.destroy!
      end
    end
    scheduled = nil
    travel_to Time.zone.local(2026, 11, 25, 9, 59, 59) do
      scheduled = create_booking(slot_number: 3)
      assert_not operation(scheduled).call
    end
    travel_to Time.zone.local(2026, 11, 25, 10) do
      assert operation(scheduled).call
    end
  end

  test "all incompatible checkin states and other dates are rejected without changing audit or times" do
    travel_to Time.zone.local(2026, 11, 25, 12) do
      %w[em_operacao liberado cancelado reagendamento].each do |status|
        booking = create_booking(status: status, checkin_at: 1.hour.ago, released_at: Time.current, release_remark: "Concluído")
        assert_no_difference "AuditEvent.count" do
          assert_not operation(booking).call
          assert_equal status, booking.reload.status
        end
        booking.destroy!
      end
      [ -1, 1 ].each do |offset|
        booking = create_booking(booking_date: Date.current + offset)
        assert_not operation(booking).call
        assert_nil booking.reload.checkin_at
      end
    end
  end

  test "an open operation from any date prevents late checkin on that physical dock" do
    travel_to Time.zone.local(2026, 11, 25, 11, 20) do
      previous = create_booking(booking_date: Date.current - 1, status: "em_operacao", checkin_at: 1.day.ago)
      booking = create_booking
      op = operation(booking)
      assert_not op.call
      assert_equal :conflict, op.http_status
      assert_includes op.errors[:base], BookingCheckinPolicy::MESSAGES[:occupied]
      assert_equal "agendado", booking.reload.status
      assert_equal "em_operacao", previous.reload.status
      assert operation(create_booking(dock_number: 2)).call
    end
  end

  test "missing malformed or stale versions never overwrite either transition" do
    travel_to Time.zone.local(2026, 11, 25, 10) do
      booking = create_booking
      [ nil, "bad", "0x", "-1", "1", "9999999999999999" ].each do |version|
        op = operation(booking, lock_version: version)
        assert_not op.call
        assert_equal :conflict, op.http_status
      end
      assert operation(booking).call
      stale = operation(booking, "release", release_remark: "Concluído")
      assert_not stale.call
      assert_equal "em_operacao", booking.reload.status
      assert_equal 1, AuditEvent.where(entity_id: booking.id).count
    end
  end

  test "release preserves checkin and slot capacity while physically freeing the dock" do
    travel_to Time.zone.local(2026, 11, 25, 10, 25) do
      booking = create_booking(status: "em_operacao", checkin_at: Time.current - 25.minutes, slot_number: 3)
      original = booking.checkin_at
      available_before = Admin::Dashboard.new(date: Date.current).indicators
      assert_difference "AuditEvent.count", 1 do
        assert operation(booking, "release", release_remark: "  Operação concluída sem ocorrências.  ").call
      end
      booking.reload
      assert_equal "liberado", booking.status
      assert_equal Time.current, booking.released_at
      assert_equal original, booking.checkin_at
      assert_equal "Operação concluída sem ocorrências.", booking.release_remark
      assert_not Booking.where(dock_number: 1, status: "em_operacao").exists?
      assert_not BookingAvailability.new(date: Date.current, dock_number: 1).available?(3)
      assert_equal available_before, Admin::Dashboard.new(date: Date.current).indicators
      event = AuditEvent.find_by!(entity_id: booking.id, action: "release")
      assert_equal "em_operacao", event.previous_values["status"]
      assert_equal "liberado", event.new_values["status"]
      assert_equal booking.release_remark, event.new_values["release_remark"]
      assert operation(create_booking(slot_number: 1)).call
    end
  end

  test "release is allowed after hours and across Sao Paulo midnight" do
    [ Time.zone.local(2026, 11, 25, 17, 31), Time.zone.local(2026, 11, 25, 18, 15), Time.zone.local(2026, 11, 26, 0, 1) ].each do |now|
      travel_to now do
        booking = create_booking(booking_date: Date.new(2026, 11, 25), status: "em_operacao", checkin_at: Time.zone.local(2026, 11, 25, 17, 20), slot_number: 10)
        assert operation(booking, "release", release_remark: "Concluído").call
        assert_equal now, booking.reload.released_at
        booking.destroy!
      end
    end
  end

  test "release rejects all invalid states notes and a clock before checkin" do
    travel_to Time.zone.local(2026, 11, 25, 10) do
      %w[agendado liberado cancelado reagendamento].each do |status|
        booking = create_booking(status: status, checkin_at: 1.hour.ago, released_at: Time.current, release_remark: "Anterior")
        assert_not operation(booking, "release", release_remark: "Concluído").call
        assert_equal "Anterior", booking.reload.release_remark
        booking.destroy!
      end
      booking = create_booking(status: "em_operacao", checkin_at: 1.hour.ago)
      [ nil, "", "   ", "\u00a0\u00a0\u00a0", "ab", "a" * 501 ].each do |remark|
        op = operation(booking, "release", release_remark: remark)
        assert_not op.call
        assert op.errors[:release_remark].any?
        assert_nil booking.reload.released_at
      end
      assert operation(booking, "release", release_remark: "á" * 500).call
      future = create_booking(dock_number: 2, status: "em_operacao", checkin_at: 1.minute.from_now)
      assert_not operation(future, "release", release_remark: "Concluído").call
      assert_nil future.reload.released_at
    end
  end

  test "audit failures roll back both operations completely" do
    travel_to Time.zone.local(2026, 11, 25, 10) do
      booking = create_booking
      AuditEvent.stub(:create!, ->(*) { raise ActiveRecord::RecordInvalid.new(AuditEvent.new) }) do
        assert_not operation(booking).call
      end
      assert_equal "agendado", booking.reload.status
      assert_nil booking.checkin_at
      assert_equal 0, booking.lock_version
      assert operation(booking).call
      AuditEvent.stub(:create!, ->(*) { raise ActiveRecord::RecordInvalid.new(AuditEvent.new) }) do
        assert_not operation(booking, "release", release_remark: "Concluído").call
      end
      assert_equal "em_operacao", booking.reload.status
      assert_nil booking.released_at
      assert_nil booking.release_remark
      assert_equal 1, booking.lock_version
      assert_equal 1, AuditEvent.where(entity_id: booking.id).count
    end
  end

  test "checkin uses the Sao Paulo operational date at UTC midnight boundaries" do
    booking = create_booking(booking_date: Date.new(2026, 11, 26))
    travel_to Time.utc(2026, 11, 26, 2, 59) do
      assert_equal Date.new(2026, 11, 25), Date.current
      assert_equal :date, BookingCheckinPolicy.reason(booking)
      assert_not operation(booking).call
    end
    travel_to Time.utc(2026, 11, 26, 3) do
      assert_equal Date.new(2026, 11, 26), Date.current
      assert_equal :early, BookingCheckinPolicy.reason(booking)
      assert_not operation(booking).call
    end
    travel_to Time.utc(2026, 11, 26, 11) do
      assert operation(booking).call
      assert_equal 8, booking.reload.checkin_at.hour
      assert_equal Date.new(2026, 11, 26), booking.checkin_at.to_date
    end
  end

  test "overdue is a visual condition with full dates and exact window end" do
    booking = create_booking(status: "em_operacao", checkin_at: Time.zone.local(2026, 11, 25, 8))
    ending = AgendaDefinition.slot_end(booking.booking_date, 1)
    assert_not booking.operation_overdue?(now: ending - 1.second)
    assert booking.operation_overdue?(now: ending)
    assert booking.operation_overdue?(now: ending + 1.day)
    booking.status = "liberado"
    assert_not booking.operation_overdue?(now: ending + 1.day)
    booking.status = "em_operacao"
    booking.slot_number = 10
    last = AgendaDefinition.slot_end(booking.booking_date, 10)
    assert_equal "17:48", last.strftime("%H:%M")
    assert_not booking.operation_overdue?(now: last - 1.second)
    assert booking.operation_overdue?(now: last)
  end
end
