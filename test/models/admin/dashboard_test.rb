require "test_helper"
require_relative "../../support/booking_data"

class Admin::DashboardTest < ActiveSupport::TestCase
  include BookingData

  test "indicators and cells count only capacity records and retain released capacity" do
    travel_to Time.zone.local(2026, 11, 25, 7) do
      date = Date.current + 1
      %w[agendado em_operacao liberado cancelado reagendamento].each_with_index do |status, index|
        Booking.create!(booking_attributes(booking_date: date, slot_number: index + 1, status: status,
          operation: index == 1 ? "coleta" : "entrega", checkin_at: Time.current, released_at: Time.current, release_remark: "Conferido"))
      end
      SlotBlock.create!(blocked_date: date, dock_number: 2, slot_number: 1)
      Booking.create!(booking_attributes(booking_date: date - 1, dock_number: 8))
      dashboard = Admin::Dashboard.new(date: date)
      assert_equal({ bookings: 3, available: 76, deliveries: 2, pickups: 1 }, dashboard.indicators)
      assert_equal "agendado", dashboard.cell(1, 1).state
      assert_equal "em_operacao", dashboard.cell(1, 2).state
      assert_equal "liberado", dashboard.cell(1, 3).state
      [ 4, 5 ].each { |slot| assert_equal "available", dashboard.cell(1, slot).state }
      assert_equal "blocked", dashboard.cell(2, 1).state
    end
  end

  test "historical cancellations do not conceal active reservations or blocks" do
    date = Date.current + 1
    %w[cancelado reagendamento agendado].each do |status|
      Booking.create!(booking_attributes(booking_date: date, status: status))
    end
    SlotBlock.create!(blocked_date: date, dock_number: 1, slot_number: 2)
    Booking.create!(booking_attributes(booking_date: date, status: "cancelado", slot_number: 2))
    dashboard = Admin::Dashboard.new(date: date)
    assert_equal "agendado", dashboard.cell(1, 1).state
    assert_equal "blocked", dashboard.cell(1, 2).state
    assert_equal 1, dashboard.indicators[:bookings]
    assert_equal 78, dashboard.indicators[:available]
  end

  test "overlap is visible and never corrected or double counted" do
    date = Date.current + 1
    booking = Booking.create!(booking_attributes(booking_date: date))
    SlotBlock.create!(blocked_date: date, dock_number: 1, slot_number: 1)
    assert_no_difference [ "Booking.count", "SlotBlock.count", "AuditEvent.count" ] do
      dashboard = Admin::Dashboard.new(date: date)
      assert_equal "inconsistent", dashboard.cell(1, 1).state
      assert_equal booking, dashboard.cell(1, 1).booking
      assert_equal 1, dashboard.indicators[:bookings]
      assert_equal 79, dashboard.indicators[:available]
    end
  end

  test "past starts and dates outside the horizon are not available but records retain their state" do
    travel_to Time.zone.local(2026, 11, 25, 11) do
      today = Admin::Dashboard.new(date: Date.current)
      assert_equal "ended", today.cell(1, 4).state
      assert_equal "available", today.cell(1, 5).state
      assert_equal 48, today.indicators[:available]
      [ -1, 3, 30 ].each do |offset|
        date = Date.current + offset
        Booking.create!(booking_attributes(booking_date: date, dock_number: 1))
        SlotBlock.create!(blocked_date: date, dock_number: 2, slot_number: 1)
        dashboard = Admin::Dashboard.new(date: date)
        assert_equal 0, dashboard.indicators[:available]
        assert_equal "agendado", dashboard.cell(1, 1).state
        assert_equal "blocked", dashboard.cell(2, 1).state
        assert_equal offset.negative? ? "ended" : "outside_horizon", dashboard.cell(3, 1).state
      end
      [ 1, 2 ].each { |offset| assert_equal 80, Admin::Dashboard.new(date: Date.current + offset).indicators[:available] }
    end
  end

  test "availability uses Sao Paulo midnight and the exact slot start" do
    travel_to Time.utc(2026, 11, 26, 2, 59) do
      assert_equal 0, Admin::Dashboard.new(date: Date.current).indicators[:available]
      assert_equal 80, Admin::Dashboard.new(date: Date.new(2026, 11, 27)).indicators[:available]
      assert_equal 0, Admin::Dashboard.new(date: Date.new(2026, 11, 28)).indicators[:available]
    end
    travel_to Time.utc(2026, 11, 26, 3) do
      assert_equal 80, Admin::Dashboard.new(date: Date.current).indicators[:available]
      assert_equal 80, Admin::Dashboard.new(date: Date.new(2026, 11, 28)).indicators[:available]
    end
  end

  test "all eighty cells use grouped queries plus one global pending count" do
    # Load schema metadata before recording application SQL.
    Booking.columns
    SlotBlock.columns
    queries = []
    callback = ->(*args) do
      payload = args.last
      queries << payload[:sql] if payload[:sql].match?(/\ASELECT\b/i) && payload[:sql].match?(/"(?:bookings|slot_blocks)"/)
    end
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      dashboard = Admin::Dashboard.new(date: Date.current + 1)
      AgendaDefinition::DOCK_NUMBERS.each do |dock|
        AgendaDefinition::SLOT_NUMBERS.each { |slot| dashboard.cell(dock, slot) }
      end
      dashboard.indicators
    end
    assert_equal 3, queries.size, queries.inspect
  end
end
