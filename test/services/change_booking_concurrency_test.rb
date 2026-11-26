require "test_helper"
require_relative "../support/booking_data"

class ChangeBookingConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false
  include BookingData

  setup do
    @ids = []
    @request_ids = []
  end

  teardown do
    ids = (@ids + Booking.where(request_id: @request_ids).pluck(:id)).uniq
    with_audit_cleanup { AuditEvent.where(entity_type: "Booking", entity_id: ids).delete_all }
    Booking.where(id: ids).delete_all
  end

  test "two alterations to the same destination confirm only one" do
    travel_to Time.zone.local(2026, 11, 25, 9) do
      first = make_booking(dock_number: 7)
      second = make_booking(dock_number: 8)
      race(change_actor(first), change_actor(second))
      assert_equal 1, Booking.where(booking_date: Date.current + 2, dock_number: 6, slot_number: 10).count
    end
  end

  test "administrative alteration and public creation compete under the same position lock" do
    travel_to Time.zone.local(2026, 11, 25, 9) do
      original = make_booking(dock_number: 8)
      attributes = booking_attributes(booking_date: Date.current + 2, dock_number: 6, slot_number: 10, operation: "coleta").except(:protocol)
      @request_ids << attributes[:request_id]
      public_actor = -> { result = CreateBooking.call(BookingRequest.new(attributes)); [ result.present?, result&.id ] }
      race(change_actor(original), public_actor)
      assert_equal 1, Booking.where(booking_date: Date.current + 2, dock_number: 6, slot_number: 10).count
      assert_equal 1, AuditEvent.where(entity_type: "Booking", entity_id: @ids + Booking.where(request_id: @request_ids).pluck(:id)).count
    end
  end

  test "cancellation and checkin cannot both confirm against one version" do
    travel_to Time.zone.local(2026, 11, 25, 9) do
      original = make_booking(booking_date: Date.current, dock_number: 8)
      race(change_actor(original, "cancel"), checkin_actor(original))
      assert_includes %w[cancelado em_operacao], original.reload.status
    end
  end

  test "alteration and checkin preserve the winning transition" do
    travel_to Time.zone.local(2026, 11, 25, 9) do
      original = make_booking(booking_date: Date.current, dock_number: 8)
      race(change_actor(original), checkin_actor(original))
      original.reload
      assert(original.status == "em_operacao" || original.booking_date == Date.current + 2)
    end
  end

  test "a move and a cancel using the same version cannot both confirm" do
    travel_to Time.zone.local(2026, 11, 25, 9) do
      original = make_booking(dock_number: 8)
      race(change_actor(original), change_actor(original, "cancel"))
      assert_equal 1, original.reload.lock_version
    end
  end

  test "two simultaneous cancellations produce one audit" do
    travel_to Time.zone.local(2026, 11, 25, 9) do
      original = make_booking(dock_number: 8)
      race(change_actor(original, "cancel"), change_actor(original, "cancel"))
      assert_equal "cancelado", original.reload.status
      assert_equal 1, AuditEvent.where(entity_id: original.id, action: "cancel").count
    end
  end

  test "two awaiting reschedule bookings cannot both acquire the same new position" do
    travel_to Time.zone.local(2026, 11, 25, 9) do
      first = make_booking(status: "reagendamento", dock_number: 7, booking_date: Date.current - 1)
      second = make_booking(status: "reagendamento", dock_number: 8, booking_date: Date.current - 1)
      race(change_actor(first), change_actor(second))
      assert_equal 1, Booking.where(id: @ids, status: "agendado").count
      assert_equal 1, Booking.where(id: @ids, status: "reagendamento").count
    end
  end

  private

  def make_booking(overrides = {})
    record = Booking.create!(booking_attributes(booking_date: Date.current + 1).merge(overrides))
    @ids << record.id
    record
  end

  def change_actor(record, action = "reschedule")
    -> do
      form = BookingChangeRequest.new(booking_date: Date.current + 2, dock_number: 6, slot_number: 10,
        change_reason: "Operação concorrente de teste", lock_version: 0)
      operation = ChangeBooking.new(booking_id: record.id, action: action, form: form)
      [ operation.call, operation.booking&.id ]
    end
  end

  def checkin_actor(record)
    -> do
      operation = OperateBooking.new(booking_id: record.id, action: "checkin", lock_version: 0)
      [ operation.call, operation.booking&.id ]
    end
  end

  def race(*actors)
    ready, start, winner, commit, results = Array.new(5) { Queue.new }
    threads = actors.map do |actor|
      Thread.new do
        ApplicationRecord.connection_pool.with_connection do |connection|
          connection.transaction do
            connection.execute("SET LOCAL statement_timeout = '12s'")
            ready << connection.raw_connection.backend_pid
            raise "Start timeout" unless start.pop(timeout: 10)

            result = actor.call
            if result.first
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
    winner_pid = winner.pop(timeout: 10)
    assert winner_pid, "No operation succeeded"
    wait_for_block((pids - [ winner_pid ]).first)
    commit << true
    threads.each { |thread| assert thread.join(15), "Concurrent operation timeout" }
    outcomes = Array.new(2) { results.pop(timeout: 1) }
    outcomes.each { |outcome| assert_kind_of Array, outcome, outcome.inspect }
    assert_equal 1, outcomes.count(&:first)
    all_ids = @ids + Booking.where(request_id: @request_ids).pluck(:id)
    assert_equal 1, AuditEvent.where(entity_type: "Booking", entity_id: all_ids).count
  ensure
    2.times { start << true }
    2.times { commit << true }
    threads&.each { |thread| thread.join(15) || thread.kill.join }
  end

  def wait_for_block(pid)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 4
    loop do
      bind = ActiveRecord::Relation::QueryAttribute.new("pid", pid, ActiveRecord::Type::Integer.new)
      blocked = ApplicationRecord.connection.exec_query("SELECT cardinality(pg_blocking_pids($1)) > 0 AS blocked", "Observe contention", [ bind ]).first.fetch("blocked")
      return if blocked
      flunk "No real PostgreSQL contention observed" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
      sleep 0.01
    end
  end
end
