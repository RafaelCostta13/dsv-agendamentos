require "test_helper"

class EnvironmentTest < ActiveSupport::TestCase
  test "test database is isolated and uses PostgreSQL" do
    assert Rails.env.test?
    assert_equal "PostgreSQL", ActiveRecord::Base.connection.adapter_name
    assert_equal 1, ActiveRecord::Base.connection.select_value("SELECT 1")

    configurations = ActiveRecord::Base.configurations
    development = configurations.configs_for(env_name: "development", name: "primary")
    testing = configurations.configs_for(env_name: "test", name: "primary")
    production = configurations.configs_for(env_name: "production", name: "primary")
    assert_equal "#{development.database}_test", testing.database
    refute_equal development.database, testing.database
    refute_equal production.database, testing.database
    assert_equal testing.database, ActiveRecord::Base.connection.select_value("SELECT current_database()")
  end

  test "application uses Brazilian Portuguese and Sao Paulo time with UTC persistence" do
    assert_equal :"pt-BR", I18n.default_locale
    assert_equal "DSV Doca Agenda", I18n.t("app.name")
    assert_equal "America/Sao_Paulo", Time.zone.tzinfo.name
    assert_equal :utc, ActiveRecord.default_timezone
    assert_equal "2026-11-25 09:00:00 -0300", Time.utc(2026, 11, 25, 12).in_time_zone.strftime("%Y-%m-%d %H:%M:%S %z")
  end
end
