class ProtectAuditEvents < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE FUNCTION prevent_audit_event_mutation() RETURNS trigger
      LANGUAGE plpgsql AS $$
      BEGIN
        RAISE EXCEPTION 'audit_events is append-only' USING ERRCODE = '23514';
      END;
      $$;
      CREATE TRIGGER audit_events_append_only
      BEFORE UPDATE OR DELETE ON audit_events
      FOR EACH ROW EXECUTE FUNCTION prevent_audit_event_mutation();
    SQL
  end

  def down
    execute "DROP TRIGGER audit_events_append_only ON audit_events"
    execute "DROP FUNCTION prevent_audit_event_mutation()"
  end
end
