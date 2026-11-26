class AuthenticateUser
  DUMMY_DIGEST = BCrypt::Password.create("invalid credential comparison",
    cost: Rails.env.test? ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost).to_s.freeze
  attr_reader :user, :retry_after

  def initialize(email:, password:, ip:)
    @email = email.is_a?(String) && email.bytesize <= 1024 ? email.strip.downcase : ""
    @password = password.is_a?(String) && password.bytesize.between?(1, 72) && !password.include?("\0") ? password : ""
    @ip = ip
  end

  def call
    result = LoginRateLimiter.new(email: @email, ip: @ip).call do
      ApplicationRecord.transaction(requires_new: true) do
        candidate = User.lock.find_by(email: @email)
        authenticated = candidate ? candidate.authenticate(@password) : BCrypt::Password.new(DUMMY_DIGEST).is_password?(@password)
        @user = candidate if authenticated && candidate.active?
        yield @user if @user && block_given?
        @user.present?
      end
    end
    @retry_after = result.retry_after
    result.allowed && @user.present?
  end

  def rate_limited?
    retry_after.present?
  end
end
