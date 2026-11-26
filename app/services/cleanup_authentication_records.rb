class CleanupAuthenticationRecords
  def call(now: Time.current)
    sessions = Session.where("COALESCE(revoked_at, expires_at) < ?", now - Session::RETENTION).delete_all
    attempts = LoginAttempt.where(occurred_at: ...(now - 1.day)).delete_all
    { sessions: sessions, login_attempts: attempts }
  end
end
