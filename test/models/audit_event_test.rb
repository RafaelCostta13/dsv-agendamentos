require "test_helper"
require_relative "../support/booking_data"

class AuditEventTest < ActiveSupport::TestCase
  include BookingData

  test "event round trips JSONB while its optional actor uses a protected user reference" do
    event = AuditEvent.create!(entity_type: "SlotBlock", entity_id: 123, action: "unblocked",
      previous_values: { "dock_number" => 1, "slot_number" => 3 },
      new_values: { "dock_number" => 2, "slot_number" => 5 })
    assert_equal({ "dock_number" => 1, "slot_number" => 3 }, event.reload.previous_values)
    assert_equal({ "dock_number" => 2, "slot_number" => 5 }, event.new_values)
    assert event.created_at
    refute_includes AuditEvent.column_names, "updated_at"
    assert_equal [ :actor_user ], AuditEvent.reflect_on_all_associations.map(&:name)
    assert_equal [ "users" ], ActiveRecord::Base.connection.foreign_keys(:audit_events).map(&:to_table)
  end

  test "model requires structural fields without defining an operational action list" do
    event = AuditEvent.new
    assert_not event.valid?
    %i[entity_type entity_id action].each { |field| assert event.errors[field].any? }
    assert AuditEvent.new(entity_type: "Booking", entity_id: 1, action: "future_action").valid?
  end

  test "database requires mandatory fields and limits entity types and action length" do
    attributes = { entity_type: "Booking", entity_id: 1, action: "created" }
    %i[entity_type entity_id action created_at].each do |field|
      assert_database_rejects ActiveRecord::NotNullViolation, AuditEvent, attributes.merge(field => nil)
    end
    assert_database_rejects ActiveRecord::StatementInvalid, AuditEvent, attributes.merge(entity_type: "Unknown")
    assert_database_rejects ActiveRecord::ValueTooLong, AuditEvent, attributes.merge(action: "x" * 51)
  end
end
