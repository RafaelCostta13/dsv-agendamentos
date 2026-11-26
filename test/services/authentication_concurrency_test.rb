require "test_helper"

class AuthenticationConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @user = create_user(role: "operator", must_change_password: false)
  end

  teardown do
    Session.where(user_id: @user.id).delete_all
    with_audit_cleanup { AuditEvent.where(entity_type: "User", entity_id: @user.id).delete_all }
    User.where(id: @user.id).delete_all
    LoginAttempt.where(key_digest: OpenSSL::Digest::SHA256.hexdigest("email:#{@user.email}")).delete_all
    LoginAttempt.where(key_digest: OpenSSL::Digest::SHA256.hexdigest("ip:192.0.2.240")).delete_all
  end

  test "password reset commits before a waiting login rejects the old password" do
    pending = -> do
      auth = AuthenticateUser.new(email: @user.email, password: "Frase de teste com espaços!", ip: "192.0.2.240")
      auth.call { |user| Session.issue!(user: user, user_agent: "concurrent test") }
    end
    result = after_locked_change(pending) do
      ManageUser.new(action: "password_reset", user_id: @user.id, lock_version: 0, reason: "Redefinição de teste",
        attributes: { password: "Senha redefinida de teste!", password_confirmation: "Senha redefinida de teste!" }).call
    end
    assert_equal false, result
    assert_equal 0, Session.where(user_id: @user.id, revoked_at: nil).count
  end

  test "revocation commits before waiting sensitive action rejects the old session" do
    credential, = Session.issue!(user: @user, user_agent: "concurrent test")
    pending = -> do
      AuthenticatedOperation.call(user: @user, session: credential, permission: :operations) { :unauthorized_execution }
    rescue AuthenticatedOperation::Denied
      :denied
    end
    result = after_locked_change(pending) { credential.revoke!; true }
    assert_equal :denied, result
  end

  private

  def after_locked_change(pending)
    waiting = Queue.new
    worker = nil
    ApplicationRecord.transaction do
      AgendaCapacityLock.lock_user_management!
      assert yield
      worker = Thread.new do
        ApplicationRecord.connection_pool.with_connection do |connection|
          waiting << connection.raw_connection.backend_pid
          pending.call
        end
      end
      pid = waiting.pop(timeout: 5)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 3
      loop do
        bind = ActiveRecord::Relation::QueryAttribute.new("pid", pid, ActiveRecord::Type::Integer.new)
        blocked = ApplicationRecord.connection.exec_query("SELECT cardinality(pg_blocking_pids($1)) > 0 AS blocked", "Observe contention", [ bind ]).first.fetch("blocked")
        break if blocked
        flunk "PostgreSQL contention not observed" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        sleep 0.01
      end
    end
    assert worker.join(10), "concurrent operation timeout"
    worker.value
  ensure
    worker&.join(10) || worker&.kill&.join
  end
end
