require "test_helper"
require_relative "../support/booking_data"

class UnblockSlotsTest < ActiveSupport::TestCase
  include BookingData

  def block(overrides = {})
    SlotBlock.create!({ blocked_date: Date.current+1, dock_number: 1, slot_number: 1, reason: "Original" }.merge(overrides))
  end

  test "individual unblock retains historical audit and restores eligible public availability" do
    form = BlockSelection.new(blocked_date: Date.current+1, dock_numbers: [ 1 ], slot_numbers: [ 1 ], reason: "Manutenção")
    assert BlockSlots.new(form).call
    record = SlotBlock.last
    operation = UnblockSlots.new(tokens: [ record.unlock_token ], expected_id: record.id.to_s)
    assert operation.preview
    assert_difference "SlotBlock.count", -1 do
      assert_difference "AuditEvent.count", 1 do
        assert operation.call
      end
    end
    assert_equal 1, operation.removed_count
    assert_equal 1, AuditEvent.where(entity_id: record.id, action: "block").count
    event = AuditEvent.find_by!(entity_id: record.id, action: "unblock")
    assert_equal "Manutenção", event.previous_values["reason"]
    assert_nil event.new_values
    assert BookingAvailability.new(date: Date.current+1, dock_number: 1).available?(1)
  end

  test "batch unblocks exact selected records normalizing duplicates without deleting other dates or docks" do
    records = [ block, block(slot_number: 2), block(dock_number: 2) ]
    operation = UnblockSlots.new(tokens: [ records[0].unlock_token, records[0].unlock_token, records[2].unlock_token ])
    assert operation.call
    assert_equal 2, operation.removed_count
    assert_equal [ records[1].id ], SlotBlock.pluck(:id)
    assert_equal 2, AuditEvent.where(action: "unblock").count
  end

  test "bad tampered excessive and mismatched identifiers do not remove blocks" do
    record = block
    [ nil, [], "1", [ record.id.to_s ], [ "invalid" ], [ record.unlock_token+"x" ], [ record.unlock_token ]*81, [ { id: record.id } ] ].each do |tokens|
      assert_no_difference [ "SlotBlock.count", "AuditEvent.count" ] do
        assert_not UnblockSlots.new(tokens: tokens).call
      end
    end
    assert_not UnblockSlots.new(tokens: [ record.unlock_token ], expected_id: (record.id+1).to_s).call
  end

  test "a changed or missing selected record rejects the whole batch and keeps unchanged records" do
    first = block
    second = block(slot_number: 2)
    tokens = [ first.unlock_token, second.unlock_token ]
    second.update!(reason: "Alterado")
    operation = UnblockSlots.new(tokens: tokens)
    assert_not operation.call
    assert_equal :conflict, operation.http_status
    assert_equal 2, SlotBlock.count
    second.destroy!
    assert_not UnblockSlots.new(tokens: tokens).call
    assert SlotBlock.exists?(first.id)
    assert_equal 0, AuditEvent.count
  end

  test "signed revision detects microsecond timestamp changes and expiry" do
    record = block
    token = record.unlock_token
    record.update_columns(updated_at: record.updated_at + Rational(1, 1_000_000))
    assert_not UnblockSlots.new(tokens: [ token ]).call
    token = record.reload.unlock_token
    travel_to 3.hours.from_now do
      assert_not UnblockSlots.new(tokens: [ token ]).call
    end
    assert SlotBlock.exists?(record.id)
  end

  test "past out of horizon and exact starting slots cannot be removed" do
    travel_to Time.zone.local(2026, 11, 25, 11) do
      [ { blocked_date: Date.current-1 }, { blocked_date: Date.current+3 }, { blocked_date: Date.current, slot_number: 4 }, { blocked_date: Date.current, slot_number: 1 } ].each do |attrs|
        record = block(attrs)
        assert_not UnblockSlots.new(tokens: [ record.unlock_token ]).call
        assert SlotBlock.exists?(record.id)
      end
      record = block(blocked_date: Date.current, slot_number: 5)
      assert UnblockSlots.new(tokens: [ record.unlock_token ]).call
    end
  end

  test "audit failure in a batch rolls back deletions and audits" do
    records = [ block, block(slot_number: 2), block(slot_number: 3) ]
    tokens = records.map(&:unlock_token)
    original_create = AuditEvent.method(:create!)
    calls = 0
    AuditEvent.stub(:create!, ->(**args) { calls += 1; raise ActiveRecord::RecordInvalid.new(AuditEvent.new) if calls == 2; original_create.call(**args) }) do
      operation = UnblockSlots.new(tokens: tokens)
      assert_not operation.call
      assert_equal 0, operation.removed_count
    end
    assert_equal records.map(&:id).sort, SlotBlock.order(:id).pluck(:id)
    assert_equal 0, AuditEvent.count
  end

  test "removing an inconsistent block leaves the active reservation unavailable and unchanged" do
    record = block
    booking = Booking.create!(booking_attributes(booking_date: record.blocked_date))
    operation = UnblockSlots.new(tokens: [ record.unlock_token ])
    assert operation.call
    assert_equal 1, operation.reserved_count
    assert_equal "agendado", booking.reload.status
    assert_not BookingAvailability.new(date: record.blocked_date, dock_number: 1).available?(1)
    assert_equal 0, AuditEvent.where(entity_type: "Booking").count
  end
end
