require "test_helper"

class AuditIntegrityTest < ActiveSupport::TestCase
  test "PostgreSQL rejects instance and bulk UPDATE and DELETE while permitting append and reads" do
    event = AuditEvent.create!(entity_type: "Booking", entity_id: 987, action: "create", reason: "Original")
    operations = [
      -> { event.update!(reason: "Modified") },
      -> { AuditEvent.where(id: event.id).update_all(reason: "Modified") },
      -> { event.destroy! },
      -> { AuditEvent.where(id: event.id).delete_all }
    ]
    operations.each do |operation|
      error = assert_raises(ActiveRecord::StatementInvalid) do
        AuditEvent.transaction(requires_new: true) { operation.call }
      end
      assert_kind_of PG::CheckViolation, error.cause
      assert_equal "Original", AuditEvent.find(event.id).reason
    end
    assert_difference "AuditEvent.count", 1 do
      AuditEvent.create!(entity_type: "Booking", entity_id: 987, action: "future_action")
    end
    assert_equal :sql, Rails.application.config.active_record.schema_format
    assert_includes File.read(Rails.root.join("db/structure.sql")), "CREATE TRIGGER audit_events_append_only"
  end

  test "the trigger rolls back an entire attempted mutation transaction without deleting any history" do
    event = AuditEvent.create!(entity_type: "SlotBlock", entity_id: 1, action: "block")
    assert_no_difference "AuditEvent.count" do
      assert_raises(ActiveRecord::StatementInvalid) do
        AuditEvent.transaction(requires_new: true) do
          AuditEvent.create!(entity_type: "SlotBlock", entity_id: 2, action: "block")
          AuditEvent.where(id: event.id).delete_all
        end
      end
    end
    assert AuditEvent.exists?(event.id)
  end

  test "SQL schema restores the append only protection for a fresh installation" do
    connection = AuditEvent.connection
    original = connection.schema_search_path
    schema = "rf011_schema_#{SecureRandom.hex(6)}"
    connection.execute("CREATE SCHEMA #{schema}")
    sql = File.read(Rails.root.join("db/structure.sql")).lines.reject { |line| line.start_with?("\\") }.join
    sql = sql.gsub("public.", "#{schema}.").sub('SET search_path TO "$user", public;', "SET search_path TO #{schema};")
    connection.execute(sql)
    connection.execute("INSERT INTO #{schema}.audit_events (entity_type,entity_id,action,created_at) VALUES ('Booking',1,'create',CURRENT_TIMESTAMP)")
    assert_equal 1, connection.select_value("SELECT COUNT(*) FROM #{schema}.audit_events")
    error = assert_raises(ActiveRecord::StatementInvalid) do
      AuditEvent.transaction(requires_new: true) { connection.execute("DELETE FROM #{schema}.audit_events") }
    end
    assert_kind_of PG::CheckViolation, error.cause
  ensure
    connection.schema_search_path = original if original
    connection.execute("DROP SCHEMA IF EXISTS #{schema} CASCADE") if schema
  end
end
