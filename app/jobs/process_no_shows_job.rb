class ProcessNoShowsJob < ActiveJob::Base
  class ProcessingError < StandardError; end

  def perform
    counts = ProcessNoShows.new.call
    level = counts.values.any?(&:positive?) ? :info : :debug
    Rails.logger.public_send(level, "no_show job_id=#{job_id} at=#{Time.current.iso8601} #{counts.map { |key, value| "#{key}=#{value}" }.join(' ')}")
    raise ProcessingError, "No-show processing has failed reservations; retry at the next scheduled run" if counts[:failed].positive?

    counts
  rescue ActiveRecord::ActiveRecordError => error
    raise ProcessingError, "No-show database failure (#{error.class.name}); retry at the next scheduled run", cause: nil
  end
end
