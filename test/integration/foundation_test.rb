require "test_helper"

class FoundationTest < ActionDispatch::IntegrationTest
  setup { @authenticated_user = sign_in_as }
  test "root renders the administrative dashboard in the local environment" do
    get root_path

    assert_response :success
    assert_equal "text/html", response.media_type
    assert_select "html[lang='pt-BR']"
    assert_select "h1", "Dashboard"
    assert_select "body.admin-body"
    assert_select ".admin-matrix tbody td", count: 80
    assert_select "script[src*=dashboard_polling][nonce]", count: 1
  end

  test "responses contain a restrictive content security policy" do
    get root_path

    policy = response.headers.fetch("Content-Security-Policy")
    assert_match(/script-src 'nonce-[A-Za-z0-9+\/=]+'/, policy)
    assert_includes policy, "object-src 'none'"
    assert_includes policy, "frame-ancestors 'none'"
    refute_match(/unsafe-inline|unsafe-eval|https?:|\*/, policy)
  end

  test "liveness responds without accessing the database" do
    ActiveRecord::Base.connection_pool.stub(:with_connection, ->(*) { raise "unexpected database access" }) do
      get rails_health_check_path
      assert_response :success
    end
  end

  test "readiness queries PostgreSQL" do
    get readiness_path

    assert_response :success
    assert_equal "ok", response.body
    assert_equal "no-store", response.headers["Cache-Control"]
  end

  test "readiness hides connection errors" do
    database_unavailable = ->(*) { raise ActiveRecord::ConnectionNotEstablished, "private-host private-password" }
    ActiveRecord::Base.connection_pool.stub(:with_connection, database_unavailable) do
      get readiness_path

      assert_response :service_unavailable
      assert_equal "unavailable", response.body
      assert_equal "no-store", response.headers["Cache-Control"]
    end
  end

  test "readiness hides PostgreSQL errors" do
    database_unavailable = ->(*) { raise PG::ConnectionBad, "private-host private-password" }
    ActiveRecord::Base.connection_pool.stub(:with_connection, database_unavailable) do
      get readiness_path

      assert_response :service_unavailable
      assert_equal "unavailable", response.body
    end
  end

  test "Rails preserves CSRF protection" do
    assert ApplicationController.forgery_protection_strategy <= ActionController::RequestForgeryProtection::ProtectionMethods::Exception
    assert Rails.application.config.action_controller.default_protect_from_forgery
  end
end
