require "test_helper"
require_relative "../support/booking_data"

class ProcessNoShowsTest < ActiveSupport::TestCase
  include BookingData

  test "exact cutoff processes all windows including the last with complete identity and audit preservation" do
    travel_to Time.zone.local(2026, 11, 25, 17, 29, 59) do
      first = Booking.create!(booking_attributes(change_reason: "Motivo anterior"))
      last = Booking.create!(booking_attributes(slot_number: 10))
      original = first.attributes
      assert_equal 0, ProcessNoShows.new.call[:processed]
      travel 1.second
      assert_equal 2, ProcessNoShowsJob.perform_now[:processed]
      assert_equal "reagendamento", first.reload.status
      assert_equal "reagendamento", last.reload.status
      assert_equal ProcessNoShows::REASON, first.change_reason
      assert_equal original.except("status", "change_reason", "lock_version", "updated_at"), first.attributes.except("status", "change_reason", "lock_version", "updated_at")
      assert_equal original["lock_version"]+1, first.lock_version
      assert_equal Time.current, first.updated_at
      audit = AuditEvent.find_by!(entity_id: first.id, action: "no_show")
      assert_equal ProcessNoShows::REASON, audit.reason
      assert_equal Time.current, audit.created_at
      assert_equal "agendado", audit.previous_values["status"]
      assert_equal "Motivo anterior", audit.previous_values["change_reason"]
      assert_equal first.booking_date.iso8601, audit.previous_values["booking_date"]
      assert_equal first.dock_number, audit.previous_values["dock_number"]
      assert_equal first.slot_number, audit.previous_values["slot_number"]
      assert_equal "reagendamento", audit.new_values["status"]
      snapshot = first.attributes
      assert_no_difference "AuditEvent.count" do
        assert_equal 0, ProcessNoShowsJob.perform_now[:processed]
      end
      assert_equal snapshot, first.reload.attributes
      assert_not BookingAvailability.new(date: first.booking_date, dock_number: first.dock_number).available?(first.slot_number)
    end
  end

  test "later executions recover today and accumulated history and leave future dates alone" do
    [ [ 17, 30, 1 ], [ 17, 48, 0 ], [ 23, 59, 59 ] ].each do |hour, minute, second|
      travel_to Time.zone.local(2026, 11, 25, hour, minute, second) do
        records = [ -30, -1, 0, 1, 2 ].each_with_index.map do |offset, index|
          Booking.create!(booking_attributes(booking_date: Date.current+offset, slot_number: index+1, dock_number: hour==23 ? 8 : minute==48 ? 7 : 6))
        end
        assert_equal 3, ProcessNoShows.new.call[:processed]
        assert_equal %w[reagendamento reagendamento reagendamento agendado agendado], records.map { |r| r.reload.status }
      end
    end
  end

  test "Sao Paulo day rollover processes yesterday before cutoff without touching the new day" do
    travel_to Time.utc(2026, 11, 26, 2, 59, 59) do
      original = Booking.create!(booking_attributes(booking_date: Date.current))
      future = Booking.create!(booking_attributes(booking_date: Date.current+1))
      assert_equal Date.new(2026, 11, 25), Date.current
      assert_equal 1, ProcessNoShows.new.call[:processed]
      assert_equal "reagendamento", original.reload.status
      travel 1.second
      assert_equal Date.new(2026, 11, 26), Date.current
      assert_equal 0, ProcessNoShows.new.call[:processed]
      assert_equal "agendado", future.reload.status
      old = Booking.create!(booking_attributes(booking_date: Date.current-3))
      assert_equal 1, ProcessNoShows.new.call[:processed]
      assert_equal "reagendamento", old.reload.status
    end
  end

  test "protected states and scheduled bookings with inconsistent checkin are never modified" do
    travel_to Time.zone.local(2026, 11, 25, 18) do
      records = %w[em_operacao liberado cancelado reagendamento agendado].each_with_index.map do |status, index|
        Booking.create!(booking_attributes(status: status, slot_number: index+1, checkin_at: Time.current-2.hours,
          released_at: status=="liberado" ? Time.current-1.hour : nil, release_remark: "Conferido"))
      end
      snapshots = records.map(&:attributes)
      output = StringIO.new
      Rails.stub(:logger, ActiveSupport::Logger.new(output)) do
        counts=ProcessNoShows.new.call
        assert_equal 0, counts[:processed]
        assert_equal 1, counts[:inconsistent]
      end
      assert_equal snapshots, records.map { |r| r.reload.attributes }
      assert_equal 0, AuditEvent.where(action: "no_show").count
      assert_includes output.string, "inconsistent booking_id=#{records.last.id}"
      %w[company plate contact_name invoice].each { |field| assert_not_includes output.string, records.last.public_send(field) }
      assert records.first.operation_overdue?
      assert_equal :occupied, BookingCheckinPolicy.reason(Booking.new(booking_attributes(slot_number: 10)), now: Time.current.change(hour: 17, min: 20))
      release=OperateBooking.new(booking_id: records.first.id, action: "release", lock_version: 0, release_remark: "Saída confirmada")
      assert release.call
      assert_equal "liberado", records.first.reload.status
    end
  end

  test "arrival classification uses the window end but permits late checkin before cutoff" do
    travel_to Time.zone.local(2026, 11, 25, 7, 59, 59) do
      record=Booking.create!(booking_attributes)
      assert_equal :awaiting_arrival, record.arrival_state
      travel 1.second
      assert_equal :awaiting_checkin, record.arrival_state
      travel 1.hour
      assert record.late_arrival?
      assert_equal 0, ProcessNoShows.new.call[:processed]
      assert_nil BookingCheckinPolicy.reason(record)
      checkin=OperateBooking.new(booking_id: record.id, action: "checkin", lock_version: 0)
      assert checkin.call
      assert record.reload.operation_overdue?
      assert_nil record.arrival_state
    end
  end

  test "audit failure rolls back one reservation and continues others then retries without duplicate events" do
    travel_to Time.zone.local(2026, 11, 25, 18) do
      first=Booking.create!(booking_attributes)
      second=Booking.create!(booking_attributes(slot_number: 2))
      snapshot=first.attributes
      create=AuditEvent.method(:create!)
      AuditEvent.stub(:create!, ->(**attributes) { raise ActiveRecord::RecordInvalid.new(AuditEvent.new) if attributes[:entity_id]==first.id; create.call(**attributes) }) do
        counts=ProcessNoShows.new.call
        assert_equal 1, counts[:failed]
        assert_equal 1, counts[:processed]
        assert_raises(ProcessNoShowsJob::ProcessingError) { ProcessNoShowsJob.perform_now }
      end
      assert_equal snapshot, first.reload.attributes
      assert_equal "reagendamento", second.reload.status
      assert_equal 1, ProcessNoShows.new.call[:processed]
      assert_equal 2, AuditEvent.where(action: "no_show").count
    end
  end

  test "a new no show after rescheduling is a legitimate occurrence and original public replay cannot restore position" do
    travel_to Time.zone.local(2026, 11, 25, 18) do
      values=booking_attributes.except(:protocol)
      record=Booking.create!(values.merge(protocol: "NO-SHOW-LEGACY"))
      assert_equal 1, ProcessNoShows.new.call[:processed]
      form=BookingChangeRequest.new(booking_date: Date.current+1, dock_number: 2, slot_number: 1, change_reason: "Nova data", lock_version: record.reload.lock_version)
      assert ChangeBooking.new(booking_id: record.id, action: "reschedule", form: form).call
      replay=CreateBooking.call(BookingRequest.new(values))
      assert_equal record.id, replay.id
      assert_equal Date.current+1, replay.booking_date
      assert_equal "agendado", replay.status
      travel 1.day
      assert_equal 1, ProcessNoShows.new.call[:processed]
      assert_equal 2, AuditEvent.where(entity_id: record.id, action: "no_show").count
      assert_equal 3, record.reload.lock_version
      form=BookingChangeRequest.new(booking_date: Date.current+1, dock_number: 2, slot_number: 1, change_reason: "Outra data", lock_version: record.lock_version)
      assert ChangeBooking.new(booking_id: record.id, action: "reschedule", form: form).call
      travel_to Time.zone.local(2026, 11, 27, 8)
      assert OperateBooking.new(booking_id: record.id, action: "checkin", lock_version: record.reload.lock_version).call
      assert_equal "em_operacao", record.reload.status
      assert_equal 2, AuditEvent.where(entity_id: record.id, action: "no_show").count
    end
  end
end
