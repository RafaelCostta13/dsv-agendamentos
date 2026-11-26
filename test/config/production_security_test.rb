require "test_helper"
require "open3"

class ProductionSecurityTest < ActiveSupport::TestCase
  test "real production boot denies publication arbitrary hosts and detailed errors" do
    script = <<~RUBY
      require "securerandom"
      ENV["SECRET_KEY_BASE"] = SecureRandom.hex(64)
      require_relative "config/environment"
      require "rack/mock"
      client = Rack::MockRequest.new(Rails.application)
      base = { "HTTP_HOST" => "agenda.example.test", "HTTPS" => "on" }
      abort "admin published" unless client.get("/admin", base).status == 404
      abort "login published" unless client.get("/login", base).status == 404
      abort "host unrestricted" unless client.get("/up", base.merge("HTTP_HOST" => "attacker.example.test")).status == 403
      abort "health unavailable" unless client.get("/up", base).status == 200
      abort "readiness unavailable" unless client.get("/ready", base).status == 200
      abort "public form unavailable" unless client.get("/agendar", base).status == 200
      abort "detailed exceptions" if Rails.application.config.consider_all_requests_local
      puts "production security checks passed"
    RUBY
    output, status = Open3.capture2e({ "RAILS_ENV" => "production", "APP_HOST" => "agenda.example.test", "ADMIN_ACCESS_ENABLED" => "false" }, "ruby", "-e", script, chdir: Rails.root.to_s)
    assert status.success?, output
    assert_includes output, "production security checks passed"
  end

  test "real production boot fails closed without a configured host" do
    script = 'require "securerandom"; ENV["SECRET_KEY_BASE"] = SecureRandom.hex(64); require_relative "config/environment"'
    _, status = Open3.capture2e({ "RAILS_ENV" => "production", "APP_HOST" => nil, "ADMIN_ACCESS_ENABLED" => "false" }, "ruby", "-e", script, chdir: Rails.root.to_s)
    assert_not status.success?
  end

  test "production trusts Rails private proxy ranges without a manually configured CIDR" do
    script = <<~RUBY
      require "securerandom"
      ENV["SECRET_KEY_BASE"] = SecureRandom.hex(64)
      require_relative "config/environment"
      trusted = Rails.application.config.action_dispatch.trusted_proxies
      abort "private Docker proxy range not trusted" unless trusted.any? { |range| range.include?("172.20.0.2") }
      abort "public proxy range trusted" if trusted.any? { |range| range.include?("203.0.113.10") }
      puts "default proxy handling passed"
    RUBY
    output, status = Open3.capture2e({ "RAILS_ENV" => "production", "APP_HOST" => "agenda.example.test", "ADMIN_ACCESS_ENABLED" => "false" }, "ruby", "-e", script, chdir: Rails.root.to_s)
    assert status.success?, output
    assert_includes output, "default proxy handling passed"
  end

  test "production dummy secret is accepted only for explicit asset build boot" do
    script = 'ENV.delete("SECRET_KEY_BASE"); require_relative "config/environment"; abort "dummy secret missing" unless Rails.application.secret_key_base == "1" * 64; puts "asset build boot passed"'
    output, status = Open3.capture2e({ "RAILS_ENV" => "production", "APP_HOST" => "assets.example.test", "SECRET_KEY_BASE_DUMMY" => "1", "ADMIN_ACCESS_ENABLED" => "false" }, "ruby", "-e", script, chdir: Rails.root.to_s)
    assert status.success?, output
    assert_includes output, "asset build boot passed"
  end
end
