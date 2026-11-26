require "test_helper"
require "yaml"

class ProductionComposeTest < ActiveSupport::TestCase
  test "production services share an immutable production image and explicit migration step" do
    compose = YAML.safe_load_file(Rails.root.join("compose.production.yaml"), aliases: true)
    services = compose.fetch("services")
    %w[web worker migrate].each do |name|
      assert_equal services.fetch("web").fetch("image"), services.fetch(name).fetch("image")
      refute_includes services.fetch(name).fetch("volumes", []), ".:/rails"
      assert_includes services.fetch(name).fetch("cap_drop"), "ALL"
    end
    assert_equal "runtime", services.fetch("web").fetch("environment").fetch("APP_DATABASE_ROLE")
    assert_equal "runtime", services.fetch("worker").fetch("environment").fetch("APP_DATABASE_ROLE")
    assert_equal "migration", services.fetch("migrate").fetch("environment").fetch("APP_DATABASE_ROLE")
    assert_equal "1", services.fetch("migrate").fetch("environment").fetch("SECRET_KEY_BASE_DUMMY")
    refute services.fetch("migrate").fetch("environment").key?("SECRET_KEY_BASE")
    assert_equal "no", services.fetch("migrate").fetch("restart")
    assert_equal "unless-stopped", services.fetch("web").fetch("restart")
    assert_equal "unless-stopped", services.fetch("worker").fetch("restart")
    assert_equal "unless-stopped", services.fetch("db").fetch("restart")
  end

  test "production database is private and Puma publishes only through loopback" do
    compose = YAML.safe_load_file(Rails.root.join("compose.production.yaml"), aliases: true)
    services = compose.fetch("services")
    refute services.fetch("db").key?("ports")
    assert_equal [ "127.0.0.1:${HOST_RAILS_PORT:-3000}:3000" ], services.fetch("web").fetch("ports")
    assert_equal [ "production" ], services.fetch("db").fetch("networks")
    assert_equal true, compose.fetch("networks").fetch("production").fetch("internal")
    assert_equal "dsv_agenda_production_postgres", compose.fetch("volumes").fetch("postgres_data").fetch("name")
    assert_equal "dsv_agenda_production_storage", compose.fetch("volumes").fetch("rails_storage").fetch("name")
  end

  test "administrative secrets are isolated from runtime services and role setup uses quoted psql values" do
    compose = YAML.safe_load_file(Rails.root.join("compose.production.yaml"), aliases: true)
    database_environment = compose.fetch("services").fetch("db").fetch("environment")
    runtime_environment = compose.fetch("services").fetch("web").fetch("environment")
    refute runtime_environment.key?("POSTGRES_ADMIN_PASSWORD")
    refute runtime_environment.key?("POSTGRES_MIGRATION_PASSWORD")
    migration_environment = compose.fetch("services").fetch("migrate").fetch("environment")
    refute migration_environment.key?("POSTGRES_ADMIN_PASSWORD")
    refute migration_environment.key?("POSTGRES_APP_PASSWORD")
    assert_includes database_environment.fetch("POSTGRES_PASSWORD"), "POSTGRES_ADMIN_PASSWORD"
    assert_includes database_environment.fetch("POSTGRES_MIGRATION_PASSWORD"), "POSTGRES_MIGRATION_PASSWORD"

    role_script = Rails.root.join("deploy/postgres/10-create-application-roles.sh").read
    assert_includes role_script, "\\getenv app_password POSTGRES_APP_PASSWORD"
    assert_includes role_script, "format("
    refute_match(/set -x|echo .*PASSWORD|CREATE ROLE .*\$POSTGRES_/, role_script)
  end

  test "runtime grants preserve the append-only audit and exclude DDL ownership" do
    task = Rails.root.join("lib/tasks/production.rake").read
    guard = Rails.root.join("config/initializers/production_database_privileges.rb").read
    assert_includes task, "GRANT SELECT, INSERT ON TABLE public.audit_events"
    assert_includes task, "REVOKE UPDATE, DELETE, TRUNCATE ON TABLE public.audit_events"
    assert_includes task, "GRANT SELECT ON TABLE public.schema_migrations, public.ar_internal_metadata"
    assert_includes task, "current_user"
    %w[UPDATE DELETE TRUNCATE].each do |privilege|
      assert_includes guard, "has_table_privilege(current_user, 'public.audit_events', '#{privilege}')"
    end
    refute_match(/GRANT .*TRUNCATE|GRANT .*CREATE|GRANT .*DELETE .*public\.bookings/, task)
  end

  test "development compose still has its local source mount and is not replaced by production config" do
    compose = YAML.safe_load_file(Rails.root.join("compose.yaml"), aliases: true)
    assert_includes compose.fetch("services").fetch("web").fetch("volumes"), ".:/rails"
    assert_equal "${RAILS_ENV:-development}", compose.fetch("services").fetch("web").fetch("environment").fetch("RAILS_ENV")
  end

  test "production image is multi-stage, frozen, and runs as an unprivileged UID" do
    dockerfile = Rails.root.join("Dockerfile.production").read
    assert_equal 2, dockerfile.scan(/^FROM /).length
    assert_includes dockerfile, "BUNDLE_FROZEN=1"
    assert_includes dockerfile, "BUNDLE_WITHOUT=development:test"
    assert_includes dockerfile, "SECRET_KEY_BASE_DUMMY=1"
    assert_includes dockerfile, "USER 10001:10001"
    refute_includes dockerfile, "SECRET_KEY_BASE="
  end

  test "production image includes PostgreSQL 17 clients and writable Bundler user state" do
    dockerfile = Rails.root.join("Dockerfile.production").read
    runtime_stage = dockerfile.split(" AS runtime", 2).last

    assert_includes runtime_stage, "postgresql-client-17"
    assert_includes runtime_stage, "command -v psql && psql --version"
    assert_includes runtime_stage, "command -v pg_dump && pg_dump --version"
    assert_includes runtime_stage, "BUNDLE_USER_HOME=/tmp/bundler"
    refute_includes runtime_stage, "postgresql-17 "

    compose = YAML.safe_load_file(Rails.root.join("compose.production.yaml"), aliases: true)
    %w[web worker migrate].each do |name|
      assert compose.fetch("services").fetch(name).fetch("tmpfs").any? { |mount| mount.start_with?("/tmp:") }
    end
  end

  test "Nginx template uses a fixed host, overwrites forwarding headers, and keeps ACME on the host" do
    nginx = Rails.root.join("deploy/nginx/dsvbooking.tech.conf.example").read
    acme = Rails.root.join("deploy/nginx/dsvbooking.tech-acme.conf.example").read
    assert_includes nginx, "return 308 https://dsvbooking.tech$request_uri"
    assert_includes nginx, "proxy_set_header Host dsvbooking.tech"
    assert_includes nginx, "proxy_set_header X-Forwarded-For $remote_addr"
    assert_includes nginx, "proxy_pass http://127.0.0.1:3000"
    assert_includes nginx, "client_max_body_size 64k"
    refute_includes nginx, "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for"
    refute_includes nginx, "return 308 https://$host"
    assert_includes acme, "root /var/www/html"
    refute_includes acme, "proxy_pass"
  end

  test "production environment example keeps admin disabled and secret values blank" do
    sample = Rails.root.join(".env.production.example").read
    assert_match(/^ADMIN_ACCESS_ENABLED=false$/, sample)
    assert_match(/^SECRET_KEY_BASE=$/, sample)
    assert_match(/^POSTGRES_ADMIN_PASSWORD=$/, sample)
    assert_match(/^POSTGRES_APP_PASSWORD=$/, sample)
    assert_match(/^POSTGRES_MIGRATION_PASSWORD=$/, sample)
  end
end
