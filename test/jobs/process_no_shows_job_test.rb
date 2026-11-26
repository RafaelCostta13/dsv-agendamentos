require "test_helper"
require_relative "../support/booking_data"

class ProcessNoShowsJobTest < ActiveSupport::TestCase
  include BookingData

  test "the configured worker executes the real job immediately and on the next one minute cycle" do
    travel_to Time.zone.local(2026, 11, 25, 17, 29) do
      booking=Booking.create!(booking_attributes)
      worker=NoShowWorker.new
      cycles=0
      worker.stub(:wait_until, ->(deadline) {
        assert_in_delta 60, deadline-Process.clock_gettime(Process::CLOCK_MONOTONIC), 1
        cycles+=1
        if cycles==1
          assert_equal "agendado", booking.reload.status
          travel 1.minute
        else
          worker.stop
        end
      }) { worker.run }
      assert_equal 2, cycles
      assert_equal "reagendamento", booking.reload.status
      assert_equal 1, AuditEvent.where(action: "no_show", entity_id: booking.id).count
    end
  end

  test "database failure fails the job safely and the worker waits for the next scheduled execution" do
    service=Object.new
    def service.call
      raise ActiveRecord::ConnectionNotEstablished, "sensitive connection detail"
    end
    ProcessNoShows.stub(:new, service) do
      error=assert_raises(ProcessNoShowsJob::ProcessingError) { ProcessNoShowsJob.perform_now }
      assert_not_includes error.message, "sensitive"
      worker=NoShowWorker.new
      waits=0
      worker.stub(:wait_until, ->(deadline) { waits+=1; assert_in_delta 60, deadline-Process.clock_gettime(Process::CLOCK_MONOTONIC), 1; worker.stop }) { worker.run }
      assert_equal 1, waits
    end
  end
end
