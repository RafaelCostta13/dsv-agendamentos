require "test_helper"
require_relative "../support/booking_data"

class SlotBlockTest < ActiveSupport::TestCase
  include BookingData

  test "valid block has optional reason and structural validations" do
    block = SlotBlock.create!(blocked_date: Date.new(2026, 11, 25), dock_number: 8, slot_number: 10)
    assert_nil block.reason
    block.assign_attributes(blocked_date: nil, dock_number: 9, slot_number: 11, reason: "x" * 251)
    assert_not block.valid?
    %i[blocked_date dock_number slot_number reason].each { |field| assert block.errors[field].any? }
  end

  test "database rejects invalid docks slots dates lengths and duplicates" do
    attributes = { blocked_date: Date.new(2026, 11, 25), dock_number: 1, slot_number: 1 }
    SlotBlock.insert_all!([ attributes ])
    assert_database_rejects ActiveRecord::RecordNotUnique, SlotBlock, attributes
    [ { dock_number: 0 }, { dock_number: 9 }, { slot_number: 0 }, { slot_number: 11 } ].each do |invalid|
      assert_database_rejects ActiveRecord::StatementInvalid, SlotBlock, attributes.merge(invalid)
    end
    %i[blocked_date dock_number slot_number created_at updated_at].each do |field|
      assert_database_rejects ActiveRecord::NotNullViolation, SlotBlock, attributes.merge(field => nil)
    end
    assert_database_rejects ActiveRecord::ValueTooLong, SlotBlock, attributes.merge(reason: "x" * 251)
  end

  test "database accepts all docks and slots and a 250 character reason" do
    (1..8).each { |dock| SlotBlock.insert_all!([ { blocked_date: Date.new(2026, 11, 25), dock_number: dock, slot_number: 1 } ]) }
    (2..10).each { |slot| SlotBlock.insert_all!([ { blocked_date: Date.new(2026, 11, 25), dock_number: 1, slot_number: slot, reason: "x" * 250 } ]) }
    assert_equal 17, SlotBlock.count
  end
end
