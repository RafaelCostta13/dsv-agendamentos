require "test_helper"
require_relative "../../lib/healthcheck_migration_check"

class HealthcheckMigrationCheckTest < ActiveSupport::TestCase
  test "health endpoints reach the app even when the migration checker cannot connect" do
    app = ->(_env) { [ 200, {}, [ "alive" ] ] }
    checker = ->(_env) { raise ActiveRecord::ConnectionNotEstablished }

    ActiveRecord::Migration::CheckPending.stub(:new, ->(_app) { checker }) do
      middleware = HealthcheckMigrationCheck.new(app)
      %w[/up /ready].each do |path|
        assert_equal 200, middleware.call("PATH_INFO" => path).first
      end
    end
  end

  test "normal pages still run the migration checker" do
    app = ->(_env) { [ 200, {}, [ "home" ] ] }
    checker = ->(_env) { raise ActiveRecord::ConnectionNotEstablished }

    ActiveRecord::Migration::CheckPending.stub(:new, ->(_app) { checker }) do
      middleware = HealthcheckMigrationCheck.new(app)
      assert_raises(ActiveRecord::ConnectionNotEstablished) do
        middleware.call("PATH_INFO" => "/")
      end
    end
  end
end
