Rails.application.config.after_initialize do
  if Rails.env.production? && ENV["APP_DATABASE_ROLE"] != "migration" && ENV["SECRET_KEY_BASE_DUMMY"].blank?
    raise "TRUSTED_PROXY_CIDRS must contain the exact Nginx peer address" if ENV.fetch("TRUSTED_PROXY_CIDRS", "").blank?

    connection = ApplicationRecord.connection
    dangerous = connection.select_value(<<~SQL)
      SELECT rolsuper OR rolcreaterole OR rolcreatedb OR rolbypassrls OR rolreplication OR
        pg_get_userbyid(datdba) = current_user OR
        has_database_privilege(current_user, current_database(), 'CREATE') OR
        has_schema_privilege(current_user, 'public', 'CREATE') OR
        EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tableowner = current_user) OR
        has_table_privilege(current_user, 'public.audit_events', 'UPDATE') OR
        has_table_privilege(current_user, 'public.audit_events', 'DELETE') OR
        has_table_privilege(current_user, 'public.audit_events', 'TRUNCATE') OR
        pg_has_role(current_user, 'pg_write_all_data', 'MEMBER') OR
        pg_has_role(current_user, 'pg_read_server_files', 'MEMBER') OR
        pg_has_role(current_user, 'pg_write_server_files', 'MEMBER') OR
        pg_has_role(current_user, 'pg_execute_server_program', 'MEMBER')
      FROM pg_roles CROSS JOIN pg_database
      WHERE pg_roles.rolname = current_user AND pg_database.datname = current_database()
    SQL
    raise "Production runtime database role has excessive privileges" if dangerous
  end
end
