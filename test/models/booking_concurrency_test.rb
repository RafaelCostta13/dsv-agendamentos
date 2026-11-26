require "test_helper"
require_relative "../support/booking_data"

class BookingConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false
  include BookingData

  test "concurrent transactions cannot both reserve the same position" do
    assert_exclusive_commit(booking_attributes, booking_attributes)
  end

  test "concurrent transactions cannot both occupy the same dock on different days" do
    first = booking_attributes(status: "em_operacao", checkin_at: Time.utc(2026, 11, 25, 11))
    second = booking_attributes(status: "em_operacao", booking_date: Date.new(2026, 11, 26),
      slot_number: 2, checkin_at: Time.utc(2026, 11, 26, 11))
    assert_exclusive_commit(first, second)
  end

  private

  def assert_exclusive_commit(first, second)
    ready, start, inserted, release, results = Array.new(5) { Queue.new }
    protocols = [ first.fetch(:protocol), second.fetch(:protocol) ]
    threads = [ first, second ].map do |attributes|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          connection.transaction(requires_new: true) do
            connection.execute("SET LOCAL lock_timeout = '5s'")
            connection.execute("SET LOCAL statement_timeout = '8s'")
            ready << connection.raw_connection.backend_pid
            raise "Race start timed out" unless start.pop(timeout: 10)

            Booking.insert_all!([ attributes ])
            inserted << true
            raise "Race release timed out" unless release.pop(timeout: 10)
          end
          results << :committed
        end
      rescue ActiveRecord::RecordNotUnique
        results << :conflict
      rescue StandardError => error
        results << error
      end
    end

    pids = Array.new(2) { ready.pop(timeout: 10) }
    assert pids.all?, "Independent database connections did not become ready"
    assert_equal 2, pids.uniq.size
    2.times { start << true }
    assert inserted.pop(timeout: 10), "Neither transaction inserted a booking"
    assert wait_for_database_contention(pids), "No PostgreSQL lock contention observed"
    release << true
    outcomes = Array.new(2) { results.pop(timeout: 10) }
    assert_equal [ :committed, :conflict ], outcomes.sort_by(&:to_s), outcomes.inspect
    assert_equal 1, Booking.where(protocol: protocols).count
  ensure
    2.times { start << true; release << true }
    threads&.each { |thread| thread.join(10) || thread.kill.join }
    Booking.where(protocol: protocols).delete_all if protocols
  end

  def wait_for_database_contention(pids)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 3
    loop do
      return true if pids.any? do |pid|
        bind = ActiveRecord::Relation::QueryAttribute.new("pid", pid, ActiveRecord::Type::Integer.new)
        ActiveRecord::Base.connection.exec_query(
          "SELECT cardinality(pg_blocking_pids($1::integer)) > 0", "RF002 concurrent lock", [ bind ]
        ).rows.first.first
      end
      return false if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

      sleep 0.01
    end
  end
end
