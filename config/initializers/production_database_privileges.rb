Rails.application.config.after_initialize do
  if Rails.env.production? && ENV["ADMIN_ACCESS_ENABLED"] == "true"
    connection = ApplicationRecord.connection
    dangerous = connection.select_value(<<~SQL)
      SELECT rolsuper OR rolcreaterole OR rolcreatedb OR rolbypassrls OR
        EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tableowner = current_user) OR
        has_table_privilege(current_user, 'audit_events', 'UPDATE,DELETE,TRUNCATE')
      FROM pg_roles WHERE rolname = current_user
    SQL
    raise "Production runtime database role has excessive privileges" if dangerous
  end
end
