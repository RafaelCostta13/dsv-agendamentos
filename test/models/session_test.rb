require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "issues an unpredictable opaque credential and persists only its digest" do
    user = create_user(must_change_password: false)
    record, token = Session.issue!(user: user, user_agent: "Test browser")
    assert_operator token.bytesize, :>=, 43
    assert_equal 64, record.token_digest.length
    assert_not_equal token, record.token_digest
    assert_equal record, Session.find_by_token(token)
    assert record.valid_at?
    assert_nil Session.find_by_token("wrong")
    unicode, = Session.issue!(user: user, user_agent: "á" * 499)
    assert unicode.user_agent.valid_encoding?
  end

  test "enforces inactivity absolute expiration revocation and active user continuously" do
    user = create_user(must_change_password: false)
    now = Time.zone.local(2026, 11, 25, 10)
    record, = Session.issue!(user: user, user_agent: nil, now: now)
    assert record.valid_at?(now + 29.minutes)
    assert_not record.valid_at?(now + 31.minutes)
    record.update!(last_seen_at: now + 11.hours + 59.minutes)
    assert_not record.valid_at?(now + 12.hours)
    record.update!(revoked_at: now + 1.minute)
    assert_not record.valid_at?(now + 2.minutes)
    record.update!(revoked_at: nil)
    user.update!(active: false, deactivated_at: now)
    assert_not record.reload.valid_at?(now + 2.minutes)
  end
end
