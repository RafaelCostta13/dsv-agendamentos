require "test_helper"
require_relative "../support/booking_data"

class BookingAvailabilityTest < ActiveSupport::TestCase
  include BookingData

  test "today rejects past starts and permits future starts while future dates permit all slots" do
    travel_to Time.zone.local(2026, 11, 25, 11, 30) do
      today = BookingAvailability.new(date: Date.current, dock_number: 1)
      (1..4).each { |slot| assert_not today.available?(slot) }
      (5..10).each { |slot| assert today.available?(slot) }
      [ 1, 2 ].each do |offset|
        future = BookingAvailability.new(date: Date.current + offset, dock_number: 1)
        (1..10).each { |slot| assert future.available?(slot) }
      end
    end
  end

  test "exact start and end of day affect only the selected current date" do
    [ 11, 17, 18 ].each do |hour|
      travel_to Time.zone.local(2026, 11, 25, hour) do
        today = BookingAvailability.new(date: Date.current, dock_number: 1)
        assert_not today.available?(hour - 7) if hour <= 17
        (1..10).each { |slot| assert_not today.available?(slot) } if hour >= 17
        [ 1, 2 ].each do |offset|
          future = BookingAvailability.new(date: Date.current + offset, dock_number: 1)
          (1..10).each { |slot| assert future.available?(slot) }
        end
      end
    end
  end

  test "future reservations and blocks apply only to their date and dock" do
    travel_to Time.zone.local(2026, 11, 25, 18) do
      Booking.create!(booking_attributes(booking_date: Date.current + 1))
      SlotBlock.create!(blocked_date: Date.current + 1, dock_number: 1, slot_number: 2)
      tomorrow = BookingAvailability.new(date: Date.current + 1, dock_number: 1)
      assert_not tomorrow.available?(1)
      assert_not tomorrow.available?(2)
      assert tomorrow.available?(3)
      assert BookingAvailability.new(date: Date.current + 1, dock_number: 2).available?(1)
      assert BookingAvailability.new(date: Date.current + 2, dock_number: 1).available?(1)
    end
  end

  test "past and out of horizon dates reject every slot" do
    travel_to Time.zone.local(2026, 11, 25, 11, 30) do
      [ -1, 3 ].each do |offset|
        availability = BookingAvailability.new(date: Date.current + offset, dock_number: 1)
        (1..10).each { |slot| assert_not availability.available?(slot) }
      end
    end
  end

  test "horizon and slot starts follow Sao Paulo midnight rather than UTC midnight" do
    travel_to Time.utc(2026, 11, 26, 2, 59) do
      assert_equal Date.new(2026, 11, 25), Date.current
      assert BookingAvailability.new(date: Date.new(2026, 11, 27), dock_number: 1).available?(1)
      assert_not BookingAvailability.new(date: Date.new(2026, 11, 28), dock_number: 1).available?(1)
    end
    travel_to Time.utc(2026, 11, 26, 3) do
      assert_equal Date.new(2026, 11, 26), Date.current
      assert BookingAvailability.new(date: Date.current, dock_number: 1).available?(1)
      assert BookingAvailability.new(date: Date.new(2026, 11, 28), dock_number: 1).available?(1)
      assert_not BookingAvailability.new(date: Date.new(2026, 11, 25), dock_number: 1).available?(10)
    end
  end
end
