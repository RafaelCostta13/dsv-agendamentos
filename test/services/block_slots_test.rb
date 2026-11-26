require "test_helper"
require_relative "../support/booking_data"

class BlockSlotsTest < ActiveSupport::TestCase
  include BookingData

  def selection(overrides = {})
    BlockSelection.new({ blocked_date: Date.current + 1, dock_numbers: [ 1 ], slot_numbers: [ 1 ], reason: " Manutenção preventiva. " }.merge(overrides))
  end

  test "single block persists trimmed optional reason with one audit" do
    operation = BlockSlots.new(selection)
    assert_difference [ "SlotBlock.count", "AuditEvent.count" ], 1 do
      assert operation.call
    end
    block = SlotBlock.last
    assert_equal Date.current + 1, block.blocked_date
    assert_equal 1, block.dock_number
    assert_equal 1, block.slot_number
    assert_equal "Manutenção preventiva.", block.reason
    event = AuditEvent.find_by!(entity_type: "SlotBlock", entity_id: block.id, action: "block")
    assert_nil event.previous_values
    assert_equal block.reason, event.reason
    assert_equal block.reason, event.new_values["reason"]
    assert_equal block.blocked_date.iso8601, event.new_values["blocked_date"]
    assert BlockSlots.new(selection(dock_numbers: [ 2 ], reason: "   ")).call
    assert_nil SlotBlock.find_by!(dock_number: 2).reason
  end

  test "cartesian batches cover six ten and eighty unique positions with corresponding audit counts" do
    [ [ [ 1, 2 ], [ 1, 2, 3 ], 6 ], [ [ 3 ], (1..10).to_a, 10 ], [ (1..8).to_a, (1..10).to_a, 80 ] ].each do |docks, slots, total|
      existing = SlotBlock.count
      operation = BlockSlots.new(selection(dock_numbers: docks, slot_numbers: slots))
      assert operation.call
      assert_equal total, SlotBlock.where(blocked_date: Date.current + 1, dock_number: docks, slot_number: slots).count
      assert_equal SlotBlock.count - existing, operation.created_count
      assert_equal SlotBlock.count, AuditEvent.where(action: "block").count
    end
    assert_equal 80, SlotBlock.count
  end

  test "repeated and overlapping selections preserve existing reason and create no duplicate audit" do
    first = BlockSlots.new(selection(reason: "Original"))
    assert first.call
    original = SlotBlock.last.attributes
    repeat = BlockSlots.new(selection(reason: "Não sobrescrever"))
    assert_no_difference [ "SlotBlock.count", "AuditEvent.count" ] do
      assert repeat.call
    end
    assert_equal 0, repeat.created_count
    assert_equal 1, repeat.existing_count
    assert_equal original, SlotBlock.last.attributes
    mixed = BlockSlots.new(selection(dock_numbers: [ 1, 1, 2 ], slot_numbers: [ 1, 1, 2 ]))
    assert mixed.call
    assert_equal 3, mixed.created_count
    assert_equal 1, mixed.existing_count
    assert_equal 4, SlotBlock.count
    assert_equal 4, AuditEvent.count
  end

  test "invalid shapes ranges dates sizes and excessive reasons never write" do
    invalid = [ { blocked_date: "bad" }, { blocked_date: Date.current - 1 }, { blocked_date: Date.current + 3 },
      { dock_numbers: [] }, { dock_numbers: [ 0 ] }, { dock_numbers: [ 9 ] }, { dock_numbers: "1" }, { dock_numbers: [ 1 ] * 81 },
      { slot_numbers: [] }, { slot_numbers: [ 0 ] }, { slot_numbers: [ 11 ] }, { slot_numbers: [ "1 OR 1=1" ] },
      { slot_numbers: [ { id: 1 } ] }, { slot_numbers: [ 1 ] * 81 }, { reason: "x" * 251 } ]
    invalid.each do |input|
      assert_no_difference [ "SlotBlock.count", "AuditEvent.count" ] do
        operation = BlockSlots.new(selection(input))
        assert_not operation.call, input.inspect
        assert operation.form.errors.any?
      end
    end
  end

  test "time eligibility uses full selected dates exact starts and Sao Paulo midnight" do
    travel_to Time.zone.local(2026, 11, 25, 11, 30) do
      assert_not BlockSlots.new(selection(blocked_date: Date.current, slot_numbers: [ 4, 5 ])).call
      assert_equal 0, SlotBlock.count
      assert BlockSlots.new(selection(blocked_date: Date.current, slot_numbers: [ 5 ])).call
      [ 1, 2 ].each { |offset| assert BlockSlots.new(selection(blocked_date: Date.current+offset, slot_numbers: [ 1 ])).call }
      assert_equal (5..10).to_a, selection(blocked_date: Date.current).eligible_slots
    end
    travel_to Time.zone.local(2026, 11, 25, 12) do
      assert_not BlockSlots.new(selection(blocked_date: Date.current, slot_numbers: [ 5 ])).call
    end
    travel_to Time.utc(2026, 11, 26, 2, 59) do
      assert_equal Date.new(2026, 11, 25), Date.current
      assert BlockSlots.new(selection(blocked_date: Date.new(2026, 11, 27), slot_numbers: [ 10 ])).call
      assert_not BlockSlots.new(selection(blocked_date: Date.new(2026, 11, 28))).call
    end
    travel_to Time.utc(2026, 11, 26, 3) do
      assert_equal Date.new(2026, 11, 26), Date.current
      assert BlockSlots.new(selection(blocked_date: Date.new(2026, 11, 28))).call
    end
    assert_equal [ "17:00", "17:48" ], AgendaDefinition::SLOT_WINDOWS[10]
  end

  test "active capacity states reject the whole batch and report every conflicting position" do
    %w[agendado em_operacao liberado].each_with_index do |status, index|
      Booking.create!(booking_attributes(booking_date: Date.current+1, dock_number: index+1, slot_number: 2, status: status,
        checkin_at: 1.hour.ago, released_at: Time.current, release_remark: "Concluído"))
    end
    operation = BlockSlots.new(selection(dock_numbers: [ 1, 2, 3, 4 ], slot_numbers: [ 1, 2, 3 ]))
    assert_no_difference [ "SlotBlock.count", "AuditEvent.count", "Booking.count" ] do
      assert_not operation.call
    end
    assert_equal :conflict, operation.http_status
    assert_equal [ [ 1, 2 ], [ 2, 2 ], [ 3, 2 ] ], operation.conflicts
    %w[cancelado reagendamento].each_with_index do |status, index|
      Booking.create!(booking_attributes(booking_date: Date.current+1, dock_number: index+5, status: status))
    end
    assert BlockSlots.new(selection(dock_numbers: [ 5, 6 ])).call
  end

  test "existing overlap is rejected without changing existing blocks bookings or reason" do
    assert BlockSlots.new(selection(reason: "Original")).call
    Booking.create!(booking_attributes(booking_date: Date.current+1))
    operation = BlockSlots.new(selection(slot_numbers: [ 1, 2 ]))
    assert_no_difference [ "SlotBlock.count", "AuditEvent.count" ] do
      assert_not operation.call
    end
    assert_includes operation.form.errors[:base].join, "inconsistência"
    assert_equal "Original", SlotBlock.last.reason
  end

  test "audit failure late in a batch rolls back all new blocks and keeps previous blocks" do
    assert BlockSlots.new(selection).call
    original = SlotBlock.last.attributes
    original_create = AuditEvent.method(:create!)
    calls = 0
    AuditEvent.stub(:create!, ->(**args) { calls += 1; raise ActiveRecord::RecordInvalid.new(AuditEvent.new) if calls == 2; original_create.call(**args) }) do
      operation = BlockSlots.new(selection(dock_numbers: [ 1, 2 ], slot_numbers: [ 1, 2 ]))
      assert_not operation.call
      assert_equal :service_unavailable, operation.http_status
    end
    assert_equal 1, SlotBlock.count
    assert_equal 1, AuditEvent.count
    assert_equal original, SlotBlock.last.attributes
  end

  test "confirmation revalidates the temporal boundary after a successful preview" do
    operation = nil
    travel_to Time.zone.local(2026, 11, 25, 11, 59, 59) do
      operation = BlockSlots.new(selection(blocked_date: Date.current, slot_numbers: [ 5 ]))
      assert operation.preview
    end
    travel_to Time.zone.local(2026, 11, 25, 12) do
      assert_not operation.call
      assert_equal 0, SlotBlock.count
      assert_equal 0, AuditEvent.count
    end
  end

  test "block creation failure late in a batch rolls back prior inserts and audits" do
    original_create = SlotBlock.method(:create!)
    calls = 0
    SlotBlock.stub(:create!, ->(**args) { calls += 1; raise ActiveRecord::RecordInvalid.new(SlotBlock.new) if calls == 2; original_create.call(**args) }) do
      assert_not BlockSlots.new(selection(slot_numbers: [ 1, 2, 3 ])).call
    end
    assert_equal 0, SlotBlock.count
    assert_equal 0, AuditEvent.count
  end
end
