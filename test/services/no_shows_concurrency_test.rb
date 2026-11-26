require "test_helper"
require_relative "../support/booking_data"

class NoShowsConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests=false
  include BookingData

  setup { @ids=[] }
  teardown do
    with_audit_cleanup { AuditEvent.where(entity_type: "Booking", entity_id: @ids).delete_all }
    Booking.where(id: @ids).delete_all
  end

  test "two no show tasks cannot duplicate a transition or audit" do
    travel_to Time.zone.local(2026, 11, 25, 17, 30) do
      record=make_booking
      actor=-> { ProcessNoShows.new.process_booking(record.id) }
      assert_equal [ :processed, :ignored ], contend(actor, actor)
      assert_equal "reagendamento", record.reload.status
      assert_equal 1, record.lock_version
      assert_equal 1, AuditEvent.where(entity_id: record.id, action: "no_show").count
    end
  end

  test "valid checkin confirmed before cutoff wins against a no show waiting on the physical dock" do
    travel_to Time.zone.local(2026, 11, 25, 17, 29, 59) do
      record=make_booking
      checkin=-> { OperateBooking.new(booking_id: record.id, action: "checkin", lock_version: 0).call }
      noshow=-> { ProcessNoShows.new.process_booking(record.id) }
      assert_equal [ true, :ignored ], contend(checkin, noshow, after_first: -> { travel 1.second })
      assert_equal "em_operacao", record.reload.status
      assert_equal Time.zone.local(2026, 11, 25, 17, 29, 59), record.checkin_at
      assert_equal [ "checkin" ], AuditEvent.where(entity_id: record.id).pluck(:action)
    end
  end

  test "no show confirmed first rejects a checkin opened before cutoff" do
    travel_to Time.zone.local(2026, 11, 25, 17, 30) do
      record=make_booking
      checkin=-> { OperateBooking.new(booking_id: record.id, action: "checkin", lock_version: 0).call }
      assert_equal [ :processed, false ], contend(-> { ProcessNoShows.new.process_booking(record.id) }, checkin)
      assert_equal "reagendamento", record.reload.status
      assert_nil record.checkin_at
      assert_equal [ "no_show" ], AuditEvent.where(entity_id: record.id).pluck(:action)
    end
  end

  test "no show and cancellation honor the winning version in both orders" do
    compete_with_change("cancel", "agendado")
  end

  test "no show and alteration revalidate the new future date in both orders" do
    compete_with_change("reschedule", "agendado")
  end

  test "rescheduling an existing pending booking is not overwritten by a no show task" do
    travel_to Time.zone.local(2026, 11, 25, 18) do
      record=make_booking(status: "reagendamento")
      mover=change_actor(record, "reschedule")
      assert_equal [ true, :ignored ], contend(mover, -> { ProcessNoShows.new.process_booking(record.id) })
      assert_equal Date.current+1, record.reload.booking_date
      assert_equal "agendado", record.status
      assert_equal [ "reschedule" ], AuditEvent.where(entity_id: record.id).pluck(:action)
    end
  end

  private

  def make_booking(**values)
    record=Booking.create!(booking_attributes(values))
    @ids<<record.id
    record
  end

  def change_actor(record, action)
    -> do
      form=BookingChangeRequest.new(booking_date: Date.current+1, dock_number: 2, slot_number: 2, change_reason: "Decisão do operador", lock_version: record.lock_version)
      ChangeBooking.new(booking_id: record.id, action: action, form: form).call
    end
  end

  def compete_with_change(action, status)
    travel_to Time.zone.local(2026, 11, 25, 18) do
      [ true, false ].each_with_index do |noshow_first, index|
        record=make_booking(status: status, slot_number: index+1)
        noshow=-> { ProcessNoShows.new.process_booking(record.id) }
        mover=change_actor(record, action)
        actors=noshow_first ? [ noshow, mover ] : [ mover, noshow ]
        assert_equal(noshow_first ? [ :processed, false ] : [ true, :ignored ], contend(*actors))
        record.reload
        assert_equal(noshow_first ? "reagendamento" : action=="cancel" ? "cancelado" : "agendado", record.status)
        assert_equal(noshow_first || action=="cancel" ? Date.current : Date.current+1, record.booking_date)
        assert_equal 1, record.lock_version
        assert_equal [ noshow_first ? "no_show" : action ], AuditEvent.where(entity_id: record.id).pluck(:action)
      end
    end
  end

  def contend(first, second, after_first: -> { })
    ready, commit, results, second_ready=Array.new(4) { Queue.new }
    one=Thread.new do
      ApplicationRecord.connection_pool.with_connection do |connection|
        connection.transaction do
          result=first.call
          ready<<connection.raw_connection.backend_pid
          raise "commit timeout" unless commit.pop(timeout: 10)
          results<<result
        end
      end
    rescue StandardError=>error
      ready<<error
    end
    first_pid=ready.pop(timeout: 10)
    assert_kind_of Integer, first_pid
    after_first.call
    two=Thread.new do
      ApplicationRecord.connection_pool.with_connection do |connection|
        second_ready<<connection.raw_connection.backend_pid
        result=second.call
        results<<result
      end
    rescue StandardError=>error
      results<<error
    end
    second_pid=second_ready.pop(timeout: 10)
    assert_not_equal first_pid, second_pid
    deadline=Process.clock_gettime(Process::CLOCK_MONOTONIC)+4
    loop do
      bind=ActiveRecord::Relation::QueryAttribute.new("pid", second_pid, ActiveRecord::Type::Integer.new)
      blocked=ApplicationRecord.connection.exec_query("SELECT cardinality(pg_blocking_pids($1)) > 0 AS blocked", "Observe contention", [ bind ]).first.fetch("blocked")
      break if blocked
      flunk "No real PostgreSQL contention observed" if Process.clock_gettime(Process::CLOCK_MONOTONIC)>=deadline
      sleep 0.01
    end
    commit<<true
    assert one.join(10), "first operation timed out"
    assert two.join(10), "second operation timed out"
    # The first actor publishes before COMMIT; the waiter finishes only after it.
    Array.new(2) { results.pop(timeout: 1) }
  ensure
    commit<<true
    [ one, two ].compact.each { |thread| thread.join(10)||thread.kill.join }
  end
end
