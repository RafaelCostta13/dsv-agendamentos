require "test_helper"

class CleanupAuthenticationRecordsTest < ActiveSupport::TestCase
  test "removes only old technical records and preserves users audits and valid sessions" do
    user = create_user(must_change_password: false)
    current, = Session.issue!(user: user, user_agent: nil)
    old, = Session.issue!(user: user, user_agent: nil, now: 40.days.ago)
    old.update!(revoked_at: 35.days.ago)
    recent_attempt = LoginAttempt.create!(key_kind: "ip", key_digest: "a" * 64, occurred_at: 1.hour.ago)
    old_attempt = LoginAttempt.create!(key_kind: "ip", key_digest: "b" * 64, occurred_at: 2.days.ago)
    audit = AuditEvent.record!({ entity_type: "User", entity_id: user.id, action: "login_success" }, actor: user)
    CleanupAuthenticationRecords.new.call
    assert Session.exists?(current.id)
    assert_not Session.exists?(old.id)
    assert LoginAttempt.exists?(recent_attempt.id)
    assert_not LoginAttempt.exists?(old_attempt.id)
    assert User.exists?(user.id)
    assert AuditEvent.exists?(audit.id)
  end
end
