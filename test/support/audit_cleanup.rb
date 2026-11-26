module AuditCleanup
  # No application bypass: privileged DDL is confined to explicit test cleanup.
  def with_audit_cleanup
    raise "Audit cleanup is restricted to tests" unless Rails.env.test?
    AuditEvent.transaction do
      connection = AuditEvent.connection
      connection.execute("LOCK TABLE audit_events IN ACCESS EXCLUSIVE MODE")
      connection.execute("ALTER TABLE audit_events DISABLE TRIGGER audit_events_append_only")
      begin
        yield
      ensure
        connection.execute("ALTER TABLE audit_events ENABLE TRIGGER audit_events_append_only")
      end
    end
  end
end
