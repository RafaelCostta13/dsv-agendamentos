require "test_helper"
require_relative "../support/booking_data"

class CreateBookingConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false
  include BookingData

  test "only one concurrent submission can reserve the same position" do
    first = attributes
    second = attributes
    results = race(first, second)
    assert_equal 1, results.compact.size
  end

  test "concurrent identical request IDs return the same reservation and one audit" do
    first = attributes
    results = race(first, first.dup)
    assert_equal 2, results.compact.size
    assert_equal 1, results.uniq.size
  end

  test "concurrent incompatible submissions with the same UUID cannot both succeed" do
    first = attributes
    results = race(first, first.merge(company: "Outra empresa"))
    assert_equal 1, results.compact.size
  end

  private

  def attributes
    booking_attributes(booking_date: Date.current + 1, dock_number: 3, slot_number: 10).except(:protocol)
  end

  def race(first, second)
    ready, start, outcomes = Array.new(3) { Queue.new }
    request_ids = [ first.fetch(:request_id), second.fetch(:request_id) ]
    threads = [ first, second ].map do |input|
      Thread.new do
        ApplicationRecord.connection_pool.with_connection do |connection|
          connection.transaction do
            connection.execute("SET LOCAL statement_timeout = '8s'")
            ready << connection.raw_connection.backend_pid
            raise "Race start timeout" unless start.pop(timeout: 10)

            result = CreateBooking.call(BookingRequest.new(input))
            outcomes << result&.id
          end
        end
      rescue StandardError => error
        outcomes << error
      end
    end
    pids = Array.new(2) { ready.pop(timeout: 10) }
    assert pids.all?
    assert_equal 2, pids.uniq.size
    2.times { start << true }
    threads.each { |thread| assert thread.join(12), "Concurrent submission timeout" }
    results = Array.new(2) { outcomes.pop(timeout: 1) }
    results.each { |result| assert(result.nil? || result.is_a?(Integer), result.inspect) }
    assert_equal 1, Booking.where(request_id: request_ids).count
    ids = Booking.where(request_id: request_ids).pluck(:id)
    assert_equal 1, AuditEvent.where(entity_type: "Booking", entity_id: ids, action: "create").count
    results
  ensure
    2.times { start << true }
    threads&.each { |thread| thread.join(10) || thread.kill.join }
    if request_ids
      ids = Booking.where(request_id: request_ids).pluck(:id)
      with_audit_cleanup { AuditEvent.where(entity_type: "Booking", entity_id: ids).delete_all }
      Booking.where(request_id: request_ids).delete_all
    end
  end
end
