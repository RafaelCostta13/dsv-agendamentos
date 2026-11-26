class PublicRequestLimiter
  WINDOW = 1.minute
  LIMITS = { read: 180, availability: 120, create: 80 }.freeze

  def self.allow?(ip:, kind:, now: Time.current)
    digest = OpenSSL::Digest::SHA256.hexdigest("public:#{kind}:#{ip}")
    ApplicationRecord.transaction(requires_new: true) do
      ApplicationRecord.connection.execute("SET LOCAL lock_timeout = '3s'")
      ApplicationRecord.connection.execute(ApplicationRecord.sanitize_sql_array([ "SELECT pg_advisory_xact_lock(hashtextextended(?, 0))", digest ]))
      scope = LoginAttempt.where(key_kind: "ip", key_digest: digest, occurred_at: (now - WINDOW)..)
      return false if scope.count >= LIMITS.fetch(kind)
      LoginAttempt.create!(key_kind: "ip", key_digest: digest, occurred_at: now)
      true
    end
  end
end
