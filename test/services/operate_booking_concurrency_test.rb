require "test_helper"
require_relative "../support/booking_data"

class OperateBookingConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false
  include BookingData

  test "different vehicles cannot concurrently occupy one physical dock" do
    race("checkin", same_booking: false)
  end

  test "concurrent checkins of one reservation create only one operational audit" do
    race("checkin", same_booking: true)
  end

  test "concurrent releases cannot overwrite time remark or duplicate audit" do
    race("release", same_booking: true)
  end

  test "unique index protects against a writer that ignores the physical dock lock" do
    travel_to Time.zone.local(2026, 11, 25, 10) do
      @ids = []
      occupier = create_record("checkin", 1)
      candidate = create_record("checkin", 2)
      ready, commit, candidate_ready, results = Array.new(4) { Queue.new }
      writer = Thread.new do
        ApplicationRecord.connection_pool.with_connection do |connection|
          connection.transaction do
            connection.execute("SET LOCAL statement_timeout = '12s'")
            occupier.update!(status: "em_operacao", checkin_at: Time.current)
            ready << connection.raw_connection.backend_pid
            raise "External commit timeout" unless commit.pop(timeout: 10)
          end
        end
      rescue StandardError => error
        ready << error
      end
      writer_pid = ready.pop(timeout: 10)
      assert_kind_of Integer, writer_pid
      contender = Thread.new do
        ApplicationRecord.connection_pool.with_connection do |connection|
          candidate_ready << connection.raw_connection.backend_pid
          op = OperateBooking.new(booking_id: candidate.id, action: "checkin", lock_version: 0)
          results << [ op.call, op.http_status, op.errors[:base] ]
        end
      rescue StandardError => error
        results << error
      end
      candidate_pid = candidate_ready.pop(timeout: 10)
      refute_equal writer_pid, candidate_pid
      wait_for_block(candidate_pid)
      commit << true
      assert writer.join(15)
      assert contender.join(15)
      result = results.pop(timeout: 1)
      assert_kind_of Array, result, result.inspect
      assert_equal false, result[0]
      assert_equal :conflict, result[1]
      assert_includes result[2], BookingCheckinPolicy::MESSAGES[:occupied]
      assert_equal "agendado", candidate.reload.status
      assert_nil candidate.checkin_at
      assert_equal 0, AuditEvent.where(entity_id: @ids).count
    ensure
      commit << true if commit
      [ writer, contender ].compact.each { |thread| thread.join(15) || thread.kill.join }
      with_audit_cleanup { AuditEvent.where(entity_type: "Booking", entity_id: @ids).delete_all if @ids }
      Booking.where(id: @ids).delete_all if @ids
    end
  end

  private

  def race(action, same_booking:)
    travel_to Time.zone.local(2026, 11, 25, 10) do
      @ids = []
      first = create_record(action, 1)
      second = same_booking ? first : create_record(action, 2)
      ready, start, winner, commit, results = Array.new(5) { Queue.new }
      threads = [ first, second ].map.with_index do |booking, index|
        Thread.new do
          ApplicationRecord.connection_pool.with_connection do |connection|
            connection.transaction do
              connection.execute("SET LOCAL statement_timeout = '12s'")
              ready << connection.raw_connection.backend_pid
              raise "Start timeout" unless start.pop(timeout: 10)

              op = OperateBooking.new(booking_id: booking.id, action: action, lock_version: 0, release_remark: "Concluído #{index}")
              success = op.call
              if success
                winner << connection.raw_connection.backend_pid
                raise "Commit timeout" unless commit.pop(timeout: 10)
              end
              results << [ success, op.http_status ]
            end
          end
        rescue StandardError => error
          results << error
        end
      end
      pids = Array.new(2) { ready.pop(timeout: 10) }
      assert pids.all?
      assert_equal 2, pids.uniq.size
      2.times { start << true }
      winning_pid = winner.pop(timeout: 10)
      assert winning_pid, "No successful concurrent operation"
      loser_pid = (pids - [ winning_pid ]).first
      wait_for_block(loser_pid)
      commit << true
      threads.each { |thread| assert thread.join(15), "Concurrent operation timeout" }
      outcomes = Array.new(2) { results.pop(timeout: 1) }
      outcomes.each { |outcome| assert_kind_of Array, outcome, outcome.inspect }
      assert_equal 1, outcomes.count { |success, _| success }
      assert_equal 1, outcomes.count { |success, status| !success && status == :conflict }
      assert_equal 1, AuditEvent.where(entity_type: "Booking", entity_id: @ids, action: action).count
      assert_equal 1, Booking.where(id: @ids, status: action == "checkin" ? "em_operacao" : "liberado").count
      assert_equal 1, Booking.where(id: @ids).maximum(:lock_version)
    ensure
      2.times { start << true } if start
      2.times { commit << true } if commit
      threads&.each { |thread| thread.join(15) || thread.kill.join }
      with_audit_cleanup { AuditEvent.where(entity_type: "Booking", entity_id: @ids).delete_all if @ids }
      Booking.where(id: @ids).delete_all if @ids
    end
  end

  def create_record(action, slot)
    booking = Booking.create!(booking_attributes(booking_date: Date.current, dock_number: 8, slot_number: slot,
      status: action == "release" ? "em_operacao" : "agendado", checkin_at: action == "release" ? 1.hour.ago : nil))
    @ids << booking.id
    booking
  end

  def wait_for_block(pid)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 4
    loop do
      # pid is obtained from the driver's backend_pid, never request input.
      bind = ActiveRecord::Relation::QueryAttribute.new("pid", pid, ActiveRecord::Type::Integer.new)
      blocked = ApplicationRecord.connection.exec_query("SELECT cardinality(pg_blocking_pids($1)) > 0 AS blocked", "Observe contention", [ bind ]).first.fetch("blocked")
      return if blocked
      flunk "Concurrent operation did not block in PostgreSQL" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
      sleep 0.01
    end
  end
end
