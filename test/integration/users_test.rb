require "test_helper"
require_relative "../support/user_data"

class UsersTest < ActionDispatch::IntegrationTest
  include UserData
  setup { @authenticated_user = sign_in_as }

  test "creation is administrative uses safe fields and never echoes passwords in success or invalid forms" do
    values=user_attributes
    get new_admin_user_path
    assert_response :success
    assert_select "input[type=password][autocomplete=new-password]", count: 2
    assert_select "input[type=password][value]", count: 0
    assert_difference [ "User.count", "AuditEvent.count" ], 1 do
      post admin_users_path, params: { user: values.merge(password_digest: "FORGED", must_change_password: false, lock_version: 88, actor_id: 1, password_changed_at: "2000-01-01") }
    end
    assert_response :see_other
    user=User.find_by!(email: values[:email])
    assert user.must_change_password
    assert_equal 0, user.lock_version
    assert user.authenticate(values[:password])
    follow_redirect!
    assert_response :success
    [ values[:password], user.password_digest, "FORGED" ].each { |secret| assert_not_includes response.body, secret }
    post admin_users_path, params: { user: user_attributes(password: "too short", password_confirmation: "mismatch") }
    assert_response :unprocessable_entity
    assert_not_includes response.body, "too short"
    assert_not_includes response.body, "mismatch"
    assert_select "input[type=password][value]", count: 0
  end

  test "role change is reviewed state changes require reasons and password reset is separate" do
    user=create_user
    target_session, = Session.issue!(user: user, user_agent: "Target browser")
    digest=user.password_digest
    patch admin_user_path(user), params: { user: { name: user.name, email: user.email, role: "viewer", lock_version: 0 } }
    assert_response :success
    assert_select "h1", text: "Confirmar alteração de perfil"
    assert_equal "operator", user.reload.role
    patch admin_user_path(user), params: { intent: "confirm_role", user: { name: user.name, email: user.email, role: "viewer", lock_version: 0, password: "ignored password", active: false } }
    assert_response :see_other
    assert_equal "viewer", user.reload.role
    assert target_session.reload.revoked_at
    assert user.active
    assert_equal digest, user.password_digest
    patch deactivate_admin_user_path(user), params: { user: { lock_version: 1, reason: "" } }
    assert_response :unprocessable_entity
    patch deactivate_admin_user_path(user), params: { user: { lock_version: 1, reason: "Fim da participação" } }
    assert_response :see_other
    assert_not user.reload.active
    patch activate_admin_user_path(user), params: { user: { lock_version: 2 } }
    assert_response :see_other
    assert user.reload.active
    get edit_admin_user_path(user)
    assert_select "input[type=password]", count: 0
    get password_reset_admin_user_path(user)
    assert_select "input[type=password]", count: 2
    secret="Nova senha de teste!"
    reset_session_record, = Session.issue!(user: user, user_agent: "Target browser")
    patch password_reset_admin_user_path(user), params: { user: { lock_version: 3, password: secret, password_confirmation: secret, reason: "Solicitação administrativa" } }
    assert_response :see_other
    follow_redirect!
    assert_not_includes response.body, secret
    assert user.reload.authenticate(secret)
    assert reset_session_record.reload.revoked_at
    get admin_audit_events_path(entity_type: "User")
    assert_response :success
    assert_select ".admin-audit-table tbody tr", count: 5
    assert_includes response.body, "Senha redefinida"
    assert_not_includes response.body, user.password_digest
    event=AuditEvent.find_by!(entity_type: "User", entity_id: user.id, action: "user_password_reset")
    assert_equal @authenticated_user.id, event.actor_user_id
    assert_equal "authenticated_user", event.origin
    get admin_audit_event_path(event)
    assert_includes response.body, "Senha definida em"
    assert_not_includes response.body, user.password_digest
  end

  test "search escaped wildcards filters pagination general indicators and XSS are safe" do
    first=create_user(name: "<script>alert(1)</script>", email: "target@example.test", role: "viewer")
    27.times { |index| create_user(name: "Nome #{'%02d' % index}", email: "p#{index}@example.test") }
    inactive=create_user(name: "Conta inativa", active: false, deactivated_at: Time.current)
    get admin_users_path
    assert_response :success
    assert_select "nav a[aria-current=page]", text: /Usuários/
    assert_select ".admin-users-table tbody tr", count: 25
    assert_select "[data-user-indicator=total] strong", text: "30"
    assert_select "[data-user-indicator=active] strong", text: "29"
    assert_select "[data-user-indicator=inactive] strong", text: "1"
    assert_select "script", count: 0
    get admin_users_path(q: "TARGET@", role: "viewer", state: "active")
    assert_select ".admin-users-table tbody tr", count: 1
    assert_not_includes response.body, "<script>alert(1)</script>"
    get admin_users_path(q: "%")
    assert_select ".admin-empty"
    get admin_users_path(q: "' OR 1=1 --")
    assert_select ".admin-empty"
    get admin_users_path(role: "root")
    assert_select "[role=alert]", minimum: 1
    get admin_users_path(q: "Nome", page: 2)
    assert_select ".admin-users-table tbody tr", count: 2
    get admin_user_path(first)
    assert_not_includes response.body, first.password_digest
  end

  test "CSRF stale versions filtered credentials and production restrictions are enforced" do
    user=create_user
    protection=ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection=true
    get edit_admin_user_path(user)
    patch admin_user_path(user), params: { user: { name: "Nome novo", email: user.email, role: user.role, lock_version: 0 } }
    assert_response :unprocessable_entity
    get edit_admin_user_path(user)
    token=css_select("meta[name=csrf-token]").first["content"]
    patch admin_user_path(user), params: { authenticity_token: token, user: { name: "Nome novo", email: user.email, role: user.role, lock_version: 0 } }
    assert_response :see_other
    patch admin_user_path(user), params: { authenticity_token: token, user: { name: "Nome antigo", email: user.email, role: user.role, lock_version: 0 } }
    assert_response :conflict
    assert_equal "Nome novo", user.reload.name
    assert_includes response.headers["Content-Security-Policy"], "script-src 'none'"
    filtered=ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter({ "password"=>"secret", "password_confirmation"=>"secret", "password_digest"=>"digest", "user"=>{ "password"=>"secret" } })
    assert_equal "[FILTERED]", filtered["password"]
    assert_equal "[FILTERED]", filtered["password_digest"]
    assert_equal "[FILTERED]", filtered["user"]
    Rails.stub(:env, ActiveSupport::StringInquirer.new("production")) do
      get admin_users_path
      assert_response :not_found
    end
    routes=Rails.application.routes.routes.select { |route| route.defaults[:controller]=="admin/users" }
    assert routes.all? { |route| !route.verb.include?("DELETE") }
    assert_empty Rails.application.routes.routes.select { |route| route.defaults[:controller]=="users" }
  ensure
    ActionController::Base.allow_forgery_protection=protection
  end
end
