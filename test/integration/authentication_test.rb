require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  PASSWORD = "Senha administrativa segura!"

  test "login page authenticates normalized email and creates a protected persistent session" do
    user = create_user(email: "admin@example.test", role: "admin", must_change_password: false,
      password: PASSWORD, password_confirmation: PASSWORD)
    get login_path
    assert_response :success
    assert_select "h1.admin-sr-only", "Login"
    assert_select ".auth-intro", count: 0
    assert_select "input[autocomplete=username]"
    assert_select "input[autocomplete=current-password]"
    assert_select 'button[data-password-toggle][aria-label="Mostrar senha"][aria-controls="login_password"] svg[aria-hidden=true]'
    assert_not_includes response.body, "Agendamentos"

    assert_difference [ "Session.count", "AuditEvent.count" ], 1 do
      post login_path, params: { login: { email: "  ADMIN@EXAMPLE.TEST ", password: PASSWORD, role: "admin" } }
    end
    assert_response :see_other
    assert_redirected_to admin_root_path
    cookie = Array(response.headers.fetch("Set-Cookie")).join("\n")
    assert_includes cookie, "dsv_admin_session="
    assert_includes cookie.downcase, "httponly"
    assert_includes cookie.downcase, "samesite=lax"
    assert_not_includes cookie, Session.last.token_digest
    event = AuditEvent.order(:id).last
    assert_equal [ user.id, user.name, "admin", "authenticated_user" ], [ event.actor_user_id, event.actor_name, event.actor_role, event.origin ]
  end

  test "unknown wrong and inactive credentials use the same response without enumeration" do
    user = create_user(active: false, deactivated_at: Time.current, must_change_password: false,
      password: PASSWORD, password_confirmation: PASSWORD)
    [ [ "missing@example.test", PASSWORD ], [ user.email, "Senha totalmente incorreta" ], [ user.email, PASSWORD ] ].each do |email, password|
      post login_path, params: { login: { email: email, password: password } }
      assert_response :unprocessable_entity
      assert_select "[role=alert]", text: "E-mail ou senha inválidos."
      nonce = css_select('script[src*="authentication"]').first["nonce"]
      assert nonce.present?
      assert_includes response.headers.fetch("Content-Security-Policy"), "script-src 'nonce-#{nonce}'"
      assert_not_includes response.body, "desativada"
    end
    assert_equal 0, Session.count
  end

  test "mandatory password change restricts navigation revokes all sessions and requires a new login" do
    user = create_user(password: PASSWORD, password_confirmation: PASSWORD, must_change_password: true)
    post login_path, params: { login: { email: user.email, password: PASSWORD } }
    assert_redirected_to edit_password_path
    get admin_root_path
    assert_redirected_to edit_password_path
    get edit_password_path
    assert_response :success
    assert_select "h1", "Alteração de senha obrigatória"
    assert_select ".admin-sidebar", count: 0

    second, = Session.issue!(user: user, user_agent: "Other")
    replacement = "Nova senha administrativa segura!"
    patch password_path, params: { password_change: { current_password: PASSWORD, password: replacement, password_confirmation: replacement } }
    assert_response :see_other
    assert_redirected_to login_path
    assert Session.where(user: user).where.not(revoked_at: nil).count >= 2
    assert_not user.reload.must_change_password
    assert user.authenticate(replacement)
    assert_not user.authenticate(PASSWORD)
    assert second.reload.revoked_at
    event = AuditEvent.find_by!(entity_type: "User", entity_id: user.id, action: "password_changed")
    assert_nil event.new_values["password_digest"]
  end

  test "polling validates but does not renew activity and returns 401 when expired" do
    sign_in_as
    record = Session.order(:id).last
    seen = 20.minutes.ago
    record.update!(last_seen_at: seen)
    get admin_dashboard_refresh_path(date: Date.current.iso8601)
    assert_response :success
    assert_equal seen.to_i, record.reload.last_seen_at.to_i
    record.update!(last_seen_at: 31.minutes.ago)
    get admin_dashboard_refresh_path(date: Date.current.iso8601)
    assert_response :unauthorized
    assert_equal login_path, response.headers["X-Login-URL"]
    assert record.reload.revoked_at
  end

  test "logout revokes only the current session clears the cookie and cannot use GET" do
    user = sign_in_as
    current = Session.order(:id).last
    other, = Session.issue!(user: user, user_agent: "Other")
    delete logout_path
    assert_response :see_other
    assert current.reload.revoked_at
    assert_nil other.reload.revoked_at
    assert_includes Array(response.headers.fetch("Set-Cookie")).join("\n"), "dsv_admin_session=;"
    get admin_root_path
    assert_redirected_to login_path
    get logout_path
    assert_response :not_found
  end

  test "rate limits failed account attempts in PostgreSQL and expires the temporary counter" do
    5.times do
      post login_path, params: { login: { email: "unknown@example.test", password: "wrong" } }
      assert_response :unprocessable_entity
    end
    post login_path, params: { login: { email: "unknown@example.test", password: "wrong" } }
    assert_response :too_many_requests
    assert_operator response.headers.fetch("Retry-After").to_i, :>, 0
    email_digest = OpenSSL::Digest::SHA256.hexdigest("email:unknown@example.test")
    assert_equal 5, LoginAttempt.where(key_kind: "email", key_digest: email_digest).count
    LoginAttempt.update_all(occurred_at: 16.minutes.ago)
    post login_path, params: { login: { email: "unknown@example.test", password: "wrong" } }
    assert_response :unprocessable_entity
  end

  test "login CSRF and open redirect defenses are preserved while public booking stays public" do
    user = create_user(role: "admin", must_change_password: false, password: PASSWORD, password_confirmation: PASSWORD)
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    post login_path, params: { login: { email: user.email, password: PASSWORD } }
    assert_response :unprocessable_entity
    get login_path
    token = css_select("meta[name=csrf-token]").first["content"]
    post login_path, params: { authenticity_token: token, return_to: "https://attacker.test", login: { email: user.email, password: PASSWORD } }
    assert_response :see_other
    assert_redirected_to admin_root_path
    get new_booking_path
    assert_response :success
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  test "production authentication cookie is secure" do
    user = create_user(role: "admin", must_change_password: false, password: PASSWORD, password_confirmation: PASSWORD)
    path = login_path
    https!
    Rails.stub(:env, ActiveSupport::StringInquirer.new("production")) do
      post path, params: { login: { email: user.email, password: PASSWORD } }
    end
    cookie = Array(response.headers.fetch("Set-Cookie")).join("\n").downcase
    assert_includes cookie, "dsv_admin_session="
    assert_includes cookie, "secure"
    assert_includes cookie, "httponly"
  end
end
