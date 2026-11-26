class Session < ApplicationRecord
  INACTIVITY_TIMEOUT = 30.minutes
  ABSOLUTE_TIMEOUT = 12.hours
  RETENTION = 30.days

  belongs_to :user
  validates :token_digest, presence: true, uniqueness: true, length: { is: 64 }
  validates :last_seen_at, :expires_at, presence: true

  def self.issue!(user:, user_agent:, now: Time.current)
    token = SecureRandom.urlsafe_base64(32, false)
    record = create!(user: user, token_digest: digest(token), created_at: now, updated_at: now,
      last_seen_at: now, expires_at: now + ABSOLUTE_TIMEOUT, user_agent: user_agent.to_s.scrub[0, 500])
    [ record, token ]
  end

  def self.find_by_token(token)
    return if !token.is_a?(String) || token.bytesize > 512 || token.empty?
    find_by(token_digest: digest(token))
  end

  def self.digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token)
  end

  def valid_at?(now = Time.current)
    revoked_at.nil? && expires_at > now && last_seen_at > now - INACTIVITY_TIMEOUT && user&.active?
  end

  def revoke!(now = Time.current)
    update!(revoked_at: now) if revoked_at.nil?
  end
end
