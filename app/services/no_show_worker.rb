class NoShowWorker
  INTERVAL = 60

  def initialize
    @stopping = false
    @last_cleanup_at = nil
  end

  def stop
    @stopping = true
  end

  def run
    Rails.logger.info("no_show worker started interval_seconds=#{INTERVAL}")
    until @stopping
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      begin
        Rails.application.reloader.wrap do
          ProcessNoShowsJob.perform_now
          cleanup_authentication_records
        end
      rescue StandardError => error
        Rails.logger.error("no_show worker execution_failed error_class=#{error.class.name} retry_seconds=#{INTERVAL}")
      end
      wait_until(started + INTERVAL)
    end
  ensure
    Rails.logger.info("no_show worker stopped")
  end

  private

  def cleanup_authentication_records
    return if @last_cleanup_at && @last_cleanup_at > 1.day.ago
    counts = CleanupAuthenticationRecords.new.call
    @last_cleanup_at = Time.current
    Rails.logger.info("authentication_cleanup sessions=#{counts[:sessions]} login_attempts=#{counts[:login_attempts]}")
  end

  def wait_until(deadline)
    until @stopping
      remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
      break if remaining <= 0

      sleep([ remaining, 1 ].min)
    end
  end
end
