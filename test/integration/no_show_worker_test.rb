require "test_helper"
require "timeout"
require "rbconfig"
require_relative "../support/booking_data"

class NoShowWorkerTest < ActiveSupport::TestCase
  self.use_transactional_tests=false
  include BookingData

  setup do
    @ids = []
    @pids = []
    File.write(Rails.root.join("tmp/rf008-worker-test.log"), "")
  end
  teardown do
    @pids.dup.each { |pid| stop_worker(pid) }
    with_audit_cleanup { AuditEvent.where(entity_type: "Booking", entity_id: @ids).delete_all }
    Booking.where(id: @ids).delete_all
  end

  test "actual worker entrypoint starts without HTTP and recovers persisted backlog on restart" do
    past=make_booking(booking_date: Date.current-5)
    future=make_booking(booking_date: Date.current+2)
    first=start_worker
    wait_until { past.reload.status=="reagendamento" }
    stop_worker(first)
    another=make_booking(booking_date: Date.current-1, slot_number: 2)
    second=start_worker
    wait_until { another.reload.status=="reagendamento" }
    stop_worker(second)
    assert_equal "agendado", future.reload.status
    assert_equal 2, AuditEvent.where(entity_type: "Booking", entity_id: @ids, action: "no_show").count
    assert_equal 1, past.reload.lock_version
    text=File.read(Rails.root.join("tmp/rf008-worker-test.log"))
    assert_includes text, "worker started interval_seconds=60"
    assert_includes text, "worker stopped"
    assert_includes text, "processed=1"
    assert_not_includes text, past.company
    assert_not_includes text, past.plate
  end

  private

  def make_booking(**values)
    booking=Booking.create!(booking_attributes(values))
    @ids<<booking.id
    booking
  end

  def start_worker
    pid=Process.spawn({ "RAILS_ENV"=>"test" }, RbConfig.ruby, Rails.root.join("bin/no-show-worker").to_s,
      out: [ Rails.root.join("tmp/rf008-worker-test.log").to_s, "a" ], err: [ :child, :out ])
    @pids<<pid
    pid
  end

  def stop_worker(pid)
    return unless @pids.include?(pid)
    Process.kill("TERM", pid)
    Timeout.timeout(15) { Process.wait(pid) }
    @pids.delete(pid)
    assert $?.success?, "worker failed to exit gracefully"
  rescue Errno::ESRCH, Errno::ECHILD
    @pids.delete(pid)
  end

  def wait_until
    Timeout.timeout(15) do
      loop do
        return if yield
        sleep 0.05
      end
    end
  end
end
