namespace :production do
  desc "Apply least-privilege grants to the production application database role"
  task grant_runtime: :environment do
    abort "This task is restricted to the production migration role." unless Rails.env.production? && ENV["APP_DATABASE_ROLE"] == "migration"

    connection = ActiveRecord::Base.connection
    runtime_role = ENV.fetch("POSTGRES_APP_USER")
    quoted_role = connection.quote_table_name(runtime_role)
    actual_role = connection.select_value("SELECT current_user")
    expected_role = ENV.fetch("POSTGRES_MIGRATION_USER")
    abort "The connected PostgreSQL role does not match POSTGRES_MIGRATION_USER." unless actual_role == expected_role

    missing_tables = %w[bookings slot_blocks audit_events users sessions login_attempts schema_migrations ar_internal_metadata].reject do |table|
      connection.select_value("SELECT to_regclass(#{connection.quote("public.#{table}")}) IS NOT NULL")
    end
    abort "Production migrations are incomplete; required tables are missing." if missing_tables.any?

    connection.execute("GRANT USAGE ON SCHEMA public TO #{quoted_role}")
    connection.execute("GRANT SELECT, INSERT, UPDATE ON TABLE public.bookings TO #{quoted_role}")
    connection.execute("GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.slot_blocks, public.sessions, public.login_attempts TO #{quoted_role}")
    connection.execute("GRANT SELECT, INSERT, UPDATE ON TABLE public.users TO #{quoted_role}")
    connection.execute("GRANT SELECT, INSERT ON TABLE public.audit_events TO #{quoted_role}")
    connection.execute("GRANT SELECT ON TABLE public.schema_migrations, public.ar_internal_metadata TO #{quoted_role}")
    connection.execute("REVOKE UPDATE, DELETE, TRUNCATE ON TABLE public.audit_events FROM #{quoted_role}")
    connection.execute("REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE public.schema_migrations, public.ar_internal_metadata FROM #{quoted_role}")
    connection.execute("GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO #{quoted_role}")
  end
end
