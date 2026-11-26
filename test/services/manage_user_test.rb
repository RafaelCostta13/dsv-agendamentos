require "test_helper"
require_relative "../support/user_data"

class ManageUserTest < ActiveSupport::TestCase
  include UserData

  test "creation for all roles and inactive state is atomic and audits only allowed fields" do
    %w[admin operator viewer].each do |role|
      operation=ManageUser.new(action: "create", attributes: user_attributes(role: role))
      assert operation.call, operation.errors.map(&:message).join
      assert operation.user.must_change_password
      audit=AuditEvent.find_by!(entity_type: "User", entity_id: operation.user.id)
      assert_equal "user_created", audit.action
      assert_equal role, audit.new_values["role"]
      assert_equal operation.user.email, audit.new_values["email"]
      %w[password password_confirmation password_digest].each { |field| assert_not_includes audit.new_values.keys, field }
    end
    operation=ManageUser.new(action: "create", attributes: user_attributes(active: false))
    assert operation.call
    assert_not operation.user.active
    assert operation.user.deactivated_at
    assert_no_difference "User.count" do
      AuditEvent.stub(:create!, ->(**) { raise ActiveRecord::RecordInvalid.new(AuditEvent.new) }) do
        failure=ManageUser.new(action: "create", attributes: user_attributes)
        assert_not failure.call
        assert_equal :service_unavailable, failure.http_status
      end
    end
  end

  test "editing data and role preserves password records distinct changes and rejects stale versions" do
    user=create_user
    digest=user.password_digest
    operation=ManageUser.new(action: "update", user_id: user.id, lock_version: 0, attributes: { name: "Novo nome", role: "viewer" })
    assert operation.call
    assert_equal digest, user.reload.password_digest
    assert_equal 1, user.lock_version
    assert_equal %w[user_updated user_role_changed], AuditEvent.where(entity_type: "User", entity_id: user.id).order(:id).pluck(:action)
    stale=ManageUser.new(action: "update", user_id: user.id, lock_version: 0, attributes: { name: "Nome antigo" })
    assert_not stale.call
    assert_equal :conflict, stale.http_status
    assert_equal "Novo nome", user.reload.name
    assert_no_difference "AuditEvent.count" do
      assert ManageUser.new(action: "update", user_id: user.id, lock_version: 1, attributes: { name: "Novo nome", role: "viewer" }).call
    end
  end

  test "last active admin cannot be demoted or deactivated and other accounts can be disabled and restored" do
    admin=create_user(role: "admin")
    %w[operator viewer].each do |role|
      failure=ManageUser.new(action: "update", user_id: admin.id, lock_version: 0, attributes: { role: role })
      assert_not failure.call
      assert_equal :conflict, failure.http_status
    end
    assert_not ManageUser.new(action: "deactivate", user_id: admin.id, lock_version: 0, reason: "Mudança de equipe").call
    other=create_user(role: "admin")
    digest=other.password_digest
    assert_not ManageUser.new(action: "deactivate", user_id: other.id, lock_version: 0, reason: "  ").call
    assert ManageUser.new(action: "deactivate", user_id: other.id, lock_version: 0, reason: "  Mudança de equipe  ").call
    assert_not other.reload.active
    assert other.deactivated_at
    assert_equal "Mudança de equipe", AuditEvent.find_by!(entity_id: other.id, action: "user_deactivated").reason
    assert_no_difference "AuditEvent.count" do
      assert ManageUser.new(action: "deactivate", user_id: other.id, lock_version: 1, reason: "Não deve duplicar").call
    end
    assert ManageUser.new(action: "activate", user_id: other.id, lock_version: 1).call
    assert other.reload.active
    assert_nil other.deactivated_at
    assert_equal digest, other.password_digest
  end

  test "password reset updates flags and time excludes all credentials and rolls back on audit failure" do
    travel_to Time.zone.local(2026, 11, 25, 10) do
      user=create_user
      old=user.password_digest
      user.update!(must_change_password: false)
      values={ password: "Nova frase de teste!", password_confirmation: "Nova frase de teste!" }
      assert_not ManageUser.new(action: "password_reset", user_id: user.id, lock_version: 1, attributes: values, reason: nil).call
      assert ManageUser.new(action: "password_reset", user_id: user.id, lock_version: 1, attributes: values, reason: "Solicitação do responsável").call
      assert user.reload.authenticate(values[:password])
      assert_not_equal old, user.password_digest
      assert_equal Time.current, user.password_changed_at
      assert user.must_change_password
      audit=AuditEvent.find_by!(entity_id: user.id, action: "user_password_reset")
      assert_equal false, audit.previous_values["must_change_password"]
      [ old, user.password_digest, values[:password] ].each { |secret| assert_not_includes audit.attributes.to_json, secret }
      digest=user.password_digest
      AuditEvent.stub(:create!, ->(**) { raise ActiveRecord::StatementInvalid, "private-error" }) do
        op=ManageUser.new(action: "password_reset", user_id: user.id, lock_version: 2, attributes: user_attributes.slice(:password, :password_confirmation), reason: "Outra solicitação")
        assert_not op.call
      end
      assert_equal digest, user.reload.password_digest
      assert_equal 2, user.lock_version
    end
  end
end
