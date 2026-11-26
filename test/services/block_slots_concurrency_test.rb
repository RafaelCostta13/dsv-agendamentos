require "test_helper"
require_relative "../support/booking_data"

class BlockSlotsConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false
  include BookingData

  setup do
    @tag = "RF007-race-#{SecureRandom.hex(8)}"
    @booking_ids, @request_ids, @initial_block_ids = [], [], []
  end

  teardown do
    block_ids = (@initial_block_ids + SlotBlock.where(reason: @tag).pluck(:id)).uniq
    booking_ids = (@booking_ids + Booking.where(request_id: @request_ids).pluck(:id)).uniq
    with_audit_cleanup { AuditEvent.where(entity_type: "SlotBlock", entity_id: block_ids).delete_all }
    with_audit_cleanup { AuditEvent.where(entity_type: "Booking", entity_id: booking_ids).delete_all }
    SlotBlock.where(id: block_ids).delete_all
    Booking.where(id: booking_ids).delete_all
  end

  test "two operators blocking one position create one block and audit with an idempotent second result" do
    travel_to Time.zone.local(2026, 11, 25, 14, 30) do
      race(block_actor([ 10 ]), block_actor([ 10 ]), successes: 2, changes: 1)
      assert_equal 1, SlotBlock.where(reason: @tag).count
    end
  end

  test "blocking and public creation cannot both consume the same position" do
    travel_to Time.zone.local(2026, 11, 25, 14, 30) do
      values = booking_attributes(booking_date: Date.current+2, dock_number: 6, slot_number: 10, operation: "coleta").except(:protocol)
      @request_ids << values[:request_id]
      creator = -> { result = CreateBooking.call(BookingRequest.new(values)); [ result.present?, result ? 1 : 0 ] }
      race(block_actor([ 10 ]), creator, successes: 1, changes: 1)
      assert_equal 1, Booking.where(request_id: @request_ids).count + SlotBlock.where(reason: @tag).count
    end
  end

  test "blocking and administrative alteration cannot both acquire the destination" do
    compete_with_move("agendado")
  end

  test "blocking and rescheduling preserve the original reservation if the block wins" do
    compete_with_move("reagendamento")
  end

  test "two unlocks of the same snapshot remove once and reject the stale operation" do
    travel_to Time.zone.local(2026, 11, 25, 14, 30) do
      record = SlotBlock.create!(blocked_date: Date.current+2, dock_number: 6, slot_number: 10, reason: @tag)
      @initial_block_ids << record.id
      token = record.unlock_token
      actor = -> { op = UnblockSlots.new(tokens: [ token ]); success = op.call; [ success, op.removed_count ] }
      race(actor, actor, successes: 1, changes: 1)
      assert_not SlotBlock.exists?(record.id)
    end
  end

  test "overlapping batches serialize and do not duplicate shared positions or audits" do
    travel_to Time.zone.local(2026, 11, 25, 14, 30) do
      race(block_actor([ 8, 9 ]), block_actor([ 9, 10 ]), successes: 2, changes: 3)
      assert_equal [ 8, 9, 10 ], SlotBlock.where(reason: @tag).order(:slot_number).pluck(:slot_number)
    end
  end

  private

  def block_actor(slots)
    -> do
      op = BlockSlots.new(BlockSelection.new(blocked_date: Date.current+2, dock_numbers: [ 6 ], slot_numbers: slots, reason: @tag))
      success = op.call
      [ success, op.created_count ]
    end
  end

  def compete_with_move(status)
    travel_to Time.zone.local(2026, 11, 25, 14, 30) do
      record = Booking.create!(booking_attributes(booking_date: Date.current+1, dock_number: 8, status: status))
      @booking_ids << record.id
      mover = -> do
        form = BookingChangeRequest.new(booking_date: Date.current+2, dock_number: 6, slot_number: 10, change_reason: @tag, lock_version: 0)
        success = ChangeBooking.new(booking_id: record.id, action: "reschedule", form: form).call
        [ success, success ? 1 : 0 ]
      end
      race(block_actor([ 10 ]), mover, successes: 1, changes: 1)
      record.reload
      if SlotBlock.where(reason: @tag).exists?
        assert_equal Date.current+1, record.booking_date
        assert_equal 8, record.dock_number
        assert_equal status, record.status
        assert_equal 0, AuditEvent.where(entity_type: "Booking", entity_id: record.id).count
      else
        assert_equal Date.current+2, record.booking_date
        assert_equal 6, record.dock_number
        assert_equal "agendado", record.status
      end
    end
  end

  def race(*actors, successes:, changes:)
    ready, start, winner, commit, results = Array.new(5) { Queue.new }
    threads = actors.map do |actor|
      Thread.new do
        ApplicationRecord.connection_pool.with_connection do |connection|
          connection.transaction do
            connection.execute("SET LOCAL statement_timeout = '12s'")
            ready << connection.raw_connection.backend_pid
            raise "Start timeout" unless start.pop(timeout: 10)
            result = actor.call
            if result.first && result.last.positive?
              winner << connection.raw_connection.backend_pid
              raise "Commit timeout" unless commit.pop(timeout: 10)
            end
            results << result
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
    first = winner.pop(timeout: 10)
    assert first, "No mutating operation succeeded"
    wait_for_block((pids-[ first ]).first)
    2.times { commit << true }
    threads.each { |thread| assert thread.join(15), "Concurrent operation timed out" }
    outcomes = Array.new(2) { results.pop(timeout: 1) }
    outcomes.each { |outcome| assert_kind_of Array, outcome, outcome.inspect }
    assert_equal successes, outcomes.count(&:first)
    assert_equal changes, outcomes.sum(&:last)
    block_ids = @initial_block_ids + SlotBlock.where(reason: @tag).pluck(:id)
    booking_ids = @booking_ids + Booking.where(request_id: @request_ids).pluck(:id)
    audits = AuditEvent.where(entity_type: "SlotBlock", entity_id: block_ids).count + AuditEvent.where(entity_type: "Booking", entity_id: booking_ids).count
    assert_equal changes, audits
  ensure
    2.times { start << true }
    2.times { commit << true }
    threads&.each { |thread| thread.join(15) || thread.kill.join }
  end

  def wait_for_block(pid)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC)+4
    loop do
      bind = ActiveRecord::Relation::QueryAttribute.new("pid", pid, ActiveRecord::Type::Integer.new)
      blocked = ApplicationRecord.connection.exec_query("SELECT cardinality(pg_blocking_pids($1)) > 0 AS blocked", "Observe contention", [ bind ]).first.fetch("blocked")
      return if blocked
      flunk "No real PostgreSQL contention observed" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
      sleep 0.01
    end
  end
end
