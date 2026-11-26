require "test_helper"
require_relative "../support/booking_data"

class BookingTest < ActiveSupport::TestCase
  include BookingData

  test "valid booking preserves invoice zeros and explicit defaults" do
    booking = Booking.create!(booking_attributes)
    assert_equal "000123456", booking.reload.invoice
    assert_equal "agendado", booking.status
    assert_equal 0, booking.lock_version
    assert_nil booking.checkin_at
    assert_nil booking.released_at
  end

  test "structural validations reject invalid attributes" do
    invalid = {
      protocol: nil, request_id: nil, booking_date: nil,
      dock_number: 9, slot_number: 11, operation: "outra", status: "outro",
      contact_name: nil, company: nil, invoice: "12A", plate: "A" * 8,
      vehicle_model: nil, lock_version: -1
    }
    invalid.each do |attribute, value|
      booking = Booking.new(booking_attributes(attribute => value))
      assert_not booking.valid?, attribute.to_s
      assert booking.errors[attribute].any?, attribute.to_s
    end
  end

  test "structural validations enforce lengths and operational consistency" do
    {
      protocol: "P" * 51, contact_name: "N" * 81, company: "C" * 101,
      invoice: "1" * 45, vehicle_model: "M" * 81
    }.each do |attribute, value|
      assert_not Booking.new(booking_attributes(attribute => value)).valid?
    end
    assert_not Booking.new(booking_attributes(status: "em_operacao")).valid?
    assert_not Booking.new(booking_attributes(status: "liberado")).valid?
    assert_not Booking.new(booking_attributes(released_at: Time.current)).valid?
  end

  test "optimistic locking rejects a stale update" do
    booking = Booking.create!(booking_attributes)
    stale = Booking.find(booking.id)
    booking.update!(company: "Empresa atualizada")
    assert_equal 1, booking.lock_version
    assert_raises(ActiveRecord::StaleObjectError) { stale.update!(company: "Versão antiga") }
    assert_equal "Empresa atualizada", booking.reload.company
  end

  test "fixed backend agenda contains eight docks and ten windows ending at 1748" do
    assert_equal (1..8).to_a, AgendaDefinition::DOCK_NUMBERS.to_a
    assert_equal (1..10).to_a, AgendaDefinition::SLOT_NUMBERS.to_a
    assert_equal AgendaDefinition::SLOT_NUMBERS.to_a, AgendaDefinition::SLOT_WINDOWS.keys
    assert_equal [ "17:00", "17:48" ], AgendaDefinition::SLOT_WINDOWS.fetch(10)
  end
end
