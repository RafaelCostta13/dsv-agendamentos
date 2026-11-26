require "test_helper"

class LoginRateLimiterConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @email = "concurrent-#{SecureRandom.hex(6)}@example.test"
    @ip = "192.0.2.#{rand(1..200)}"
    @additional_digests = []
  end

  teardown do
    digests = [ OpenSSL::Digest::SHA256.hexdigest("email:#{@email}"), OpenSSL::Digest::SHA256.hexdigest("ip:#{@ip}"), *@additional_digests ]
    LoginAttempt.where(key_digest: digests).delete_all
  end

  test "concurrent failures share the PostgreSQL account limit atomically" do
    4.times { LoginRateLimiter.new(email: @email, ip: @ip).call { false } }
    ready = Queue.new
    start = Queue.new
    results = Queue.new
    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          results << LoginRateLimiter.new(email: @email, ip: @ip).call { false }
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    threads.each { |thread| thread.join(10) || flunk("rate limiter thread timeout") }
    values = 2.times.map { results.pop }
    assert_equal 1, values.count { |result| result.retry_after.present? }
    digest = OpenSSL::Digest::SHA256.hexdigest("email:#{@email}")
    assert_equal 5, LoginAttempt.where(key_kind: "email", key_digest: digest).count
  end


  test "IP limit counts successful and failed authentication attempts" do
    30.times do |index|
      email = "#{index}-#{@email}"
      @additional_digests << OpenSSL::Digest::SHA256.hexdigest("email:#{email}")
      result = LoginRateLimiter.new(email: email, ip: @ip).call { index.even? }
      assert_nil result.retry_after
    end
    blocked = LoginRateLimiter.new(email: "final-#{@email}", ip: @ip).call { true }
    assert blocked.retry_after.present?
  end
end
