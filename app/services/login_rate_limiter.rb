class LoginRateLimiter
  WINDOW = 15.minutes
  EMAIL_LIMIT = 5
  IP_LIMIT = 30
  Result = Data.define(:allowed, :retry_after)

  def initialize(email:, ip:, now: Time.current)
    @email_digest = digest("email", email.to_s.strip.downcase)
    @ip_digest = digest("ip", ip.to_s)
    @now = now
  end

  def call
    ApplicationRecord.transaction(requires_new: true) do
      lock_keys
      email_count = recent("email", @email_digest).count
      ip_count = recent("ip", @ip_digest).count
      if email_count >= EMAIL_LIMIT || ip_count >= IP_LIMIT
        oldest = [ recent("email", @email_digest).minimum(:occurred_at), recent("ip", @ip_digest).minimum(:occurred_at) ].compact.min
        return Result.new(false, [ ((oldest + WINDOW - @now).ceil), 1 ].max)
      end
      LoginAttempt.create!(key_kind: "ip", key_digest: @ip_digest, occurred_at: @now)
      success = yield
      LoginAttempt.create!(key_kind: "email", key_digest: @email_digest, occurred_at: @now) unless success
      Result.new(success, nil)
    end
  end

  private

  def recent(kind, value)
    LoginAttempt.where(key_kind: kind, key_digest: value, occurred_at: (@now - WINDOW)..)
  end

  def lock_keys
    [ @email_digest, @ip_digest ].sort.each do |value|
      ApplicationRecord.connection.execute(ApplicationRecord.sanitize_sql_array([ "SELECT pg_advisory_xact_lock(hashtextextended(?, 0))", "login-rate:#{value}" ]))
    end
  end

  def digest(kind, value)
    OpenSSL::Digest::SHA256.hexdigest("#{kind}:#{value}")
  end
end
