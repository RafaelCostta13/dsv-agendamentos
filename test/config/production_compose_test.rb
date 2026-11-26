require "test_helper"
require "yaml"

class ProductionComposeTest < ActiveSupport::TestCase
  test "production compose has only the three permanent services and a stable shared image" do
    compose = YAML.safe_load_file(Rails.root.join("compose.production.yaml"), aliases: true)
    services = compose.fetch("services")
    assert_equal %w[db web worker], services.keys.sort
    refute services.key?("migrate")
    %w[web worker].each do |name|
      assert_equal services.fetch("web").fetch("image"), services.fetch(name).fetch("image")
      refute_includes services.fetch(name).fetch("volumes", []), ".:/rails"
    end
    assert_equal "dsv-agendamentos-production:local", services.fetch("web").fetch("image")
    assert_equal "unless-stopped", services.fetch("web").fetch("restart")
    assert_equal "unless-stopped", services.fetch("worker").fetch("restart")
    assert_equal "unless-stopped", services.fetch("db").fetch("restart")
    assert_equal "service_healthy", services.fetch("web").fetch("depends_on").fetch("db").fetch("condition")
    assert_equal "service_healthy", services.fetch("worker").fetch("depends_on").fetch("db").fetch("condition")
    %w[web worker db].each do |name|
      refute services.fetch(name).fetch("privileged", false)
      refute services.fetch(name).fetch("volumes", []).any? { |mount| mount.include?("/var/run/docker.sock") }
    end
    %w[web worker].each do |name|
      %w[read_only tmpfs cap_drop security_opt].each { |setting| refute services.fetch(name).key?(setting) }
    end
  end

  test "production database and worker stay private while Puma publishes only through loopback" do
    compose = YAML.safe_load_file(Rails.root.join("compose.production.yaml"), aliases: true)
    services = compose.fetch("services")
    refute services.fetch("db").key?("ports")
    refute services.fetch("worker").key?("ports")
    assert_equal [ "127.0.0.1:${HOST_RAILS_PORT:-3000}:3000" ], services.fetch("web").fetch("ports")
    refute compose.key?("networks")
    assert services.fetch("db").fetch("healthcheck").fetch("test").last.include?("pg_isready")
    assert_equal "ruby", services.fetch("web").fetch("healthcheck").fetch("test")[1]
    assert_equal "dsv_agenda_production_postgres", compose.fetch("volumes").fetch("postgres_data").fetch("name")
    assert_equal "dsv_agenda_production_storage", compose.fetch("volumes").fetch("rails_storage").fetch("name")
  end

  test "only the database receives its admin password and setup creates one restricted application role" do
    compose = YAML.safe_load_file(Rails.root.join("compose.production.yaml"), aliases: true)
    database_environment = compose.fetch("services").fetch("db").fetch("environment")
    runtime_environment = compose.fetch("services").fetch("web").fetch("environment")
    refute runtime_environment.key?("POSTGRES_ADMIN_PASSWORD")
    refute runtime_environment.key?("POSTGRES_MIGRATION_PASSWORD")
    assert_includes database_environment.fetch("POSTGRES_PASSWORD"), "POSTGRES_ADMIN_PASSWORD"

    role_script = Rails.root.join("deploy/postgres/10-create-application-roles.sh").read
    assert_includes role_script, "\\getenv app_password POSTGRES_APP_PASSWORD"
    assert_includes role_script, "format("
    assert_includes role_script, "NOSUPERUSER NOCREATEDB NOCREATEROLE"
    refute_includes role_script, "MIGRATION"
    refute_match(/set -x|echo .*PASSWORD|CREATE ROLE .*\$POSTGRES_/, role_script)
  end

  test "production migrations are explicitly run through the web service and audit trigger remains" do
    compose = YAML.safe_load_file(Rails.root.join("compose.production.yaml"), aliases: true)
    assert_includes compose.fetch("services").fetch("web").fetch("environment").fetch("POSTGRES_USER"), "POSTGRES_APP_USER"
    refute Rails.root.join("bin/production-migrate").exist?
    refute Rails.root.join("lib/tasks/production.rake").exist?
    refute Rails.root.join("config/initializers/production_database_privileges.rb").exist?
    assert_includes Rails.root.join("db/structure.sql").read, "CREATE TRIGGER audit_events_append_only"
  end

  test "development compose still has its local source mount and is not replaced by production config" do
    compose = YAML.safe_load_file(Rails.root.join("compose.yaml"), aliases: true)
    assert_includes compose.fetch("services").fetch("web").fetch("volumes"), ".:/rails"
    assert_equal "${RAILS_ENV:-development}", compose.fetch("services").fetch("web").fetch("environment").fetch("RAILS_ENV")
  end

  test "production image is multi-stage, frozen, and uses the official root default" do
    dockerfile = Rails.root.join("Dockerfile.production").read
    assert_equal 2, dockerfile.scan(/^FROM /).length
    assert_includes dockerfile, "BUNDLE_FROZEN=1"
    assert_includes dockerfile, "BUNDLE_WITHOUT=development:test"
    assert_includes dockerfile, "SECRET_KEY_BASE_DUMMY=1"
    refute_match(/^USER\s/m, dockerfile)
    refute_includes dockerfile, "useradd"
    refute_includes dockerfile, "chown"
    refute_includes dockerfile, "SECRET_KEY_BASE="
  end

  test "production image includes PostgreSQL 17 clients and writable Bundler user state" do
    dockerfile = Rails.root.join("Dockerfile.production").read
    runtime_stage = dockerfile.split(" AS runtime", 2).last

    assert_includes runtime_stage, "postgresql-client-17"
    assert_includes runtime_stage, "command -v psql && psql --version"
    assert_includes runtime_stage, "command -v pg_dump && pg_dump --version"
    refute_includes runtime_stage, "postgresql-17 "
    refute_includes runtime_stage, "groupadd"
  end

  test "Nginx template uses a fixed host, overwrites forwarding headers, and keeps ACME on the host" do
    nginx = Rails.root.join("deploy/nginx/dsvbooking.tech.conf.example").read
    acme = Rails.root.join("deploy/nginx/dsvbooking.tech-acme.conf.example").read
    assert_includes nginx, "return 308 https://dsvbooking.tech$request_uri"
    assert_includes nginx, "proxy_set_header Host dsvbooking.tech"
    assert_includes nginx, "proxy_set_header X-Real-IP $remote_addr"
    assert_includes nginx, "proxy_set_header X-Forwarded-For $remote_addr"
    assert_includes nginx, "proxy_set_header X-Forwarded-Proto https"
    assert_includes nginx, "proxy_set_header X-Forwarded-Host dsvbooking.tech"
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
    assert_match(/^POSTGRES_APP_USER=$/, sample)
    assert_match(/^POSTGRES_APP_PASSWORD=$/, sample)
    refute_match(/^POSTGRES_MIGRATION_/, sample)
    refute_match(/^IMAGE_TAG=/, sample)
    refute_match(/^TRUSTED_PROXY_CIDRS=/, sample)
  end
end
