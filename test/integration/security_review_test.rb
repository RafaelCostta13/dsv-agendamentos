require "test_helper"

class SecurityReviewTest < ActionDispatch::IntegrationTest
  test "untrusted forwarding headers cannot rotate the login IP limit" do
    30.times do |index|
      post login_path, params: { login: { email: "missing-#{index}@example.test", password: "wrong" } },
        headers: { "X-Forwarded-For" => "198.51.100.#{index + 1}" }
      assert_response :unprocessable_entity
    end
    post login_path, params: { login: { email: "another@example.test", password: "wrong" } },
      headers: { "X-Forwarded-For" => "203.0.113.1" }
    assert_response :too_many_requests
  end

  test "public admission limits attempts without counting them as bookings" do
    digest = OpenSSL::Digest::SHA256.hexdigest("public:read:127.0.0.1")
    180.times { LoginAttempt.create!(key_kind: "ip", key_digest: digest, occurred_at: Time.current) }
    assert_no_difference [ "Booking.count", "AuditEvent.count" ] do
      get new_booking_path
      assert_response :too_many_requests
      assert_equal "60", response.headers["Retry-After"]
    end
  end

  test "oversized request is rejected before parameter parsing" do
    post login_path, params: "x=" + "a" * (64 * 1024), headers: { "CONTENT_TYPE" => "application/x-www-form-urlencoded" }
    assert_response :content_too_large
    assert_equal 0, Session.count
  end

  test "unexpected credential types and NUL fail as ordinary invalid credentials" do
    [ { password: [ "bad" ] }, { password: "abc\0bad" }, { password: "x" * 73 }, { email: { nested: "bad" } } ].each do |attributes|
      post login_path, params: { login: { email: "missing@example.test", password: "wrong" }.merge(attributes) }
      assert_response :unprocessable_entity
    end
  end

  test "missing password fields render a validation error without an internal exception" do
    sign_in_as
    patch password_path, params: { password_change: { current_password: "wrong" } }
    assert_response :unprocessable_entity
    patch password_path, params: { password_change: { current_password: "nul\0value", password: "valid-length-password", password_confirmation: "valid-length-password" } }
    assert_response :unprocessable_entity
  end

  test "database failure during authentication responds generically" do
    AuthenticateUser.stub(:new, ->(**) { raise ActiveRecord::ConnectionNotEstablished, "private database detail" }) do
      post login_path, params: { login: { email: "missing@example.test", password: "wrong" } }
      assert_response :service_unavailable
      assert_not_includes response.body, "private database detail"
    end
  end

  test "new unlisted actions are denied even on existing controllers" do
    %w[admin/users admin/audit_events admin/booking_changes admin/profiles].each do |controller|
      assert_nil AuthorizationPolicy.permission_for(controller, "future_action")
    end
  end

  test "revoked context cannot execute a critical operation" do
    user = sign_in_as
    credential = Session.order(:id).last
    credential.revoke!
    assert_raises AuthenticatedOperation::Denied do
      AuthenticatedOperation.call(user: user, session: credential, permission: :users_manage) { flunk "revoked action executed" }
    end
  end

  test "operator filter does not expose names from restricted events" do
    hidden = create_user(name: "Restricted administrator", role: "admin")
    AuditEvent.record!({ entity_type: "User", entity_id: hidden.id, action: "login_success" }, actor: hidden)
    sign_in_as(role: "operator")
    get admin_audit_events_path
    assert_response :success
    assert_not_includes response.body, hidden.name
  end
end
