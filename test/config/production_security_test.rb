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

  test "production refuses administrative publication using the privileged local database role" do
    script = 'require "securerandom"; ENV["SECRET_KEY_BASE"] = SecureRandom.hex(64); require_relative "config/environment"'
    output, status = Open3.capture2e({ "RAILS_ENV" => "production", "APP_HOST" => "agenda.example.test", "ADMIN_ACCESS_ENABLED" => "true" }, "ruby", "-e", script, chdir: Rails.root.to_s)
    assert_not status.success?
    assert_includes output, "Production runtime database role has excessive privileges"
  end
end
