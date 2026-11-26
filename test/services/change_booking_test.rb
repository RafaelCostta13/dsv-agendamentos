require "test_helper"
require_relative "../support/booking_data"

class ChangeBookingTest < ActiveSupport::TestCase
  include BookingData

  def booking(overrides = {})
    Booking.create!(booking_attributes(booking_date: Date.current + 1).merge(overrides))
  end

  def change(record, action = "reschedule", **overrides)
    values = { booking_date: Date.current + 2, dock_number: 2, slot_number: 2,
      change_reason: " Alteração solicitada pela transportadora. ", lock_version: record.lock_version }.merge(overrides)
    ChangeBooking.new(booking_id: record.id, action: action, form: BookingChangeRequest.new(values))
  end

  test "cancellation preserves identity data and position and atomically frees eligible capacity" do
    %w[agendado reagendamento].each_with_index do |status, index|
      record = booking(status: status, dock_number: index + 1, change_reason: "Motivo anterior")
      before = record.attributes
      op = change(record, "cancel")
      assert_difference "AuditEvent.count", 1 do
        assert_no_difference "Booking.count" do
          assert op.call
        end
      end
      record.reload
      assert_equal "cancelado", record.status
      assert_equal 1, record.lock_version
      assert_equal before.except("status", "change_reason", "updated_at", "lock_version"), record.attributes.except("status", "change_reason", "updated_at", "lock_version")
      assert BookingAvailability.new(date: record.booking_date, dock_number: record.dock_number).available?(record.slot_number)
      event = AuditEvent.find_by!(entity_id: record.id, action: "cancel")
      assert_equal status, event.previous_values["status"]
      assert_equal "Motivo anterior", event.previous_values["change_reason"]
      assert_equal "cancelado", event.new_values["status"]
      assert_equal record.change_reason, event.reason
      assert_empty event.new_values.keys & %w[contact_name company invoice plate vehicle_model request_id]
    end
  end

  test "cancelled past or blocked positions never become publicly eligible" do
    travel_to Time.zone.local(2026, 11, 25, 14, 30) do
      past = booking(booking_date: Date.current, slot_number: 1)
      blocked = booking(dock_number: 3)
      SlotBlock.create!(blocked_date: blocked.booking_date, dock_number: 3, slot_number: 1)
      [ past, blocked ].each do |record|
        assert change(record, "cancel").call
        assert_not BookingAvailability.new(date: record.booking_date, dock_number: record.dock_number).available?(1)
      end
    end
  end

  test "date dock window and simultaneous moves preserve the same record and audit old and new positions" do
    [ { booking_date: Date.current + 2, dock_number: 1, slot_number: 1 },
      { booking_date: Date.current + 1, dock_number: 2, slot_number: 1 },
      { booking_date: Date.current + 1, dock_number: 1, slot_number: 2 },
      { booking_date: Date.current + 2, dock_number: 3, slot_number: 3 } ].each do |destination|
      record = booking(change_reason: "Anterior")
      before = record.attributes
      assert change(record, **destination).call
      record.reload
      mutable = %w[booking_date dock_number slot_number change_reason updated_at lock_version]
      assert_equal before.except(*mutable), record.attributes.except(*mutable)
      destination.each { |field, value| assert_equal value, record.public_send(field) }
      assert_equal 1, record.lock_version
      assert BookingAvailability.new(date: before["booking_date"], dock_number: before["dock_number"]).available?(before["slot_number"])
      assert_not BookingAvailability.new(date: record.booking_date, dock_number: record.dock_number).available?(record.slot_number)
      event = AuditEvent.find_by!(entity_id: record.id, action: "reschedule")
      assert_equal before["booking_date"].iso8601, event.previous_values["booking_date"]
      assert_equal "Anterior", event.previous_values["change_reason"]
      assert_equal record.booking_date.iso8601, event.new_values["booking_date"]
      assert_equal record.change_reason, event.reason
    end
  end

  test "reagendamento returns to agendado in a valid new or same eligible position" do
    [ true, false ].each do |same|
      record = booking(status: "reagendamento")
      destination = same ? { booking_date: record.booking_date, dock_number: record.dock_number, slot_number: record.slot_number } : {}
      op = change(record, **destination)
      assert op.call
      assert_equal "agendado", record.reload.status
      assert_equal "Agendamento reagendado com sucesso.", op.notice
      event = AuditEvent.find_by!(entity_id: record.id, action: "reschedule")
      assert_equal "reagendamento", event.previous_values["status"]
      assert_equal "agendado", event.new_values["status"]
      record.reload.destroy!
    end
  end

  test "same position is a no op even after its start and without a reason" do
    travel_to Time.zone.local(2026, 11, 25, 14, 30) do
      record = booking(booking_date: Date.current, slot_number: 1)
      before = record.attributes
      op = change(record, booking_date: record.booking_date, dock_number: 1, slot_number: 1, change_reason: "")
      assert_no_difference "AuditEvent.count" do
        assert op.call
      end
      assert_equal "Nenhuma alteração foi realizada.", op.notice
      assert_equal before, record.reload.attributes
    end
  end

  test "own reservation is excluded only from its administrative availability query" do
    record = booking
    assert_not BookingAvailability.new(date: record.booking_date, dock_number: 1).available?(1)
    assert BookingAvailability.new(date: record.booking_date, dock_number: 1, excluding_booking_id: record.id).available?(1)
    SlotBlock.create!(blocked_date: record.booking_date, dock_number: 1, slot_number: 1)
    assert_not BookingAvailability.new(date: record.booking_date, dock_number: 1, excluding_booking_id: record.id).available?(1)
  end

  test "incompatible states reject both administrative operations without changing history" do
    %w[em_operacao liberado cancelado].each do |status|
      record = booking(status: status, checkin_at: 1.hour.ago, released_at: Time.current, release_remark: "Concluído")
      before = record.attributes
      %w[cancel reschedule].each do |action|
        op = change(record, action)
        assert_no_difference "AuditEvent.count" do
          assert_not op.call
        end
        assert_equal :conflict, op.http_status
        assert_equal before, record.reload.attributes
      end
      record.reload.destroy!
    end
  end

  test "invalid reasons reject cancellation and effective moves with no partial updates" do
    record = booking
    [ nil, "", "  ", "\u00a0\u00a0\u00a0", "ab", "a" * 501 ].each do |reason|
      %w[cancel reschedule].each do |action|
        op = change(record, action, change_reason: reason)
        assert_not op.call
        assert op.form.errors[:change_reason].any?
        assert_equal 0, record.reload.lock_version
      end
    end
    assert change(record, change_reason: "á" * 500).call
  end

  test "malformed and stale versions never change the reservation or the submitted version" do
    record = booking
    [ nil, "bad", "0x", "-1", "1", "99999999999999999" ].each do |version|
      %w[cancel reschedule].each do |action|
        op = change(record, action, lock_version: version)
        assert_not op.call
        assert op.version_conflict
        assert_equal :conflict, op.http_status
        assert_equal version.to_s, op.form.lock_version
      end
    end
    assert_equal 0, record.reload.lock_version
    assert_equal 0, AuditEvent.where(entity_id: record.id).count
  end

  test "position validation uses the horizon full timestamp and Sao Paulo date" do
    travel_to Time.zone.local(2026, 11, 25, 14, 30) do
      record = booking
      [ { booking_date: Date.current - 1 }, { booking_date: Date.current + 3 }, { booking_date: "invalid" },
        { booking_date: "0000-01-01" }, { dock_number: 9 }, { dock_number: "1 OR 1=1" }, { slot_number: 0 },
        { slot_number: "1.5" }, { booking_date: Date.current, slot_number: 7 } ].each do |invalid|
        assert_not change(record, **invalid).call, invalid.inspect
        assert_equal 0, record.reload.lock_version
      end
      assert change(record, booking_date: Date.current + 2, slot_number: 1).call
    end
    travel_to Time.zone.local(2026, 11, 25, 14) do
      assert_not change(booking, booking_date: Date.current, slot_number: 7).call
    end
    travel_to Time.utc(2026, 11, 26, 2, 59) do
      record = booking(booking_date: Date.new(2026, 11, 27), dock_number: 4)
      assert_not change(record, booking_date: Date.new(2026, 11, 28)).call
    end
    travel_to Time.utc(2026, 11, 26, 3) do
      record = booking(dock_number: 5)
      assert change(record, booking_date: Date.new(2026, 11, 28)).call
    end
  end

  test "active reservations and blocks reject a destination while preserving the original position" do
    record = booking
    before = record.attributes
    %w[agendado em_operacao liberado].each do |status|
      other = booking(booking_date: Date.current + 2, dock_number: 2, slot_number: 2, status: status,
        checkin_at: 1.hour.ago, released_at: Time.current, release_remark: "Concluído")
      op = change(record)
      assert_not op.call
      assert_equal :conflict, op.http_status
      assert_equal before, record.reload.attributes
      other.destroy!
    end
    SlotBlock.create!(blocked_date: Date.current + 2, dock_number: 2, slot_number: 2)
    op = change(record)
    assert_not op.call
    assert_includes op.form.errors[:slot_number], "A posição selecionada está bloqueada."
    assert_equal before, record.reload.attributes
    assert_equal 0, AuditEvent.where(entity_id: record.id).count
  end

  test "canceled and awaiting reschedule records do not block a new destination" do
    %w[cancelado reagendamento].each do |status|
      booking(booking_date: Date.current + 2, dock_number: 2, slot_number: 2, status: status)
      record = booking
      assert change(record).call
      assert_equal 1, AuditEvent.where(entity_id: record.id, action: "reschedule").count
      record.reload.destroy!
    end
  end

  test "audit failure rolls back cancellation and moves including capacity and version" do
    record = booking
    before = record.attributes
    %w[cancel reschedule].each do |action|
      AuditEvent.stub(:create!, ->(*) { raise ActiveRecord::RecordInvalid.new(AuditEvent.new) }) do
        assert_not change(record, action).call
      end
      assert_equal before, record.reload.attributes
      assert_not BookingAvailability.new(date: record.booking_date, dock_number: record.dock_number).available?(1)
      assert BookingAvailability.new(date: Date.current + 2, dock_number: 2).available?(2)
    end
    assert_equal 0, AuditEvent.where(entity_id: record.id).count
  end

  test "original public request remains idempotent after move reschedule and cancellation" do
    travel_to Time.zone.local(2026, 11, 25, 7) do
      submission = BookingRequest.new(booking_attributes(booking_date: Date.current + 1).except(:protocol))
      record = CreateBooking.call(submission)
      assert change(record).call
      record.reload
      [ "agendado", "reagendamento" ].each do |status|
        record.update!(status: status)
        assert change(record, booking_date: Date.current + 1, dock_number: 3, slot_number: status == "agendado" ? 4 : 5).call
        record.reload
        before = record.attributes
        assert_no_difference [ "Booking.count", "AuditEvent.count" ] do
          assert_equal record.id, CreateBooking.call(BookingRequest.new(submission.booking_attributes)).id
        end
        assert_equal before, record.reload.attributes
      end
      assert change(record, "cancel").call
      record.reload
      before = record.attributes
      assert_no_difference [ "Booking.count", "AuditEvent.count" ] do
        assert_equal record.id, CreateBooking.call(BookingRequest.new(submission.booking_attributes)).id
      end
      assert_equal before, record.reload.attributes
      tampered = BookingRequest.new(submission.booking_attributes.merge(booking_date: record.booking_date, dock_number: record.dock_number, slot_number: record.slot_number))
      assert_nil CreateBooking.call(tampered)
    end
  end

  test "legacy bookings without a create audit use the first administrative before values for original idempotency" do
    record = booking
    original = BookingRequest.new(record.attributes.symbolize_keys.slice(*BookingRequest::FIELDS))
    assert change(record).call
    record.reload
    assert_equal record.id, CreateBooking.call(original).id
    assert_equal Date.current + 2, record.reload.booking_date
  end
end
