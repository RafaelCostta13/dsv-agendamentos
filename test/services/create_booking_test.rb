require "test_helper"
require_relative "../support/booking_data"

class CreateBookingTest < ActiveSupport::TestCase
  include BookingData

  def form(overrides = {})
    BookingRequest.new(booking_attributes(booking_date: Date.current + 1).except(:protocol).merge(overrides))
  end

  test "creates a booking and minimal audit in one transaction" do
    submission = form(plate: "abc-1234", invoice: "00001")
    assert_difference [ "Booking.count", "AuditEvent.count" ], 1 do
      result = CreateBooking.call(submission)
      assert result.persisted?
      assert_equal "agendado", result.status
      assert_equal "ABC1234", result.plate
      assert_equal "00001", result.invoice
      assert_match(/\ADA-[A-F0-9]{24}\z/, result.protocol)
      event = AuditEvent.find_by!(entity_type: "Booking", entity_id: result.id, action: "create")
      assert_equal result.protocol, event.new_values.fetch("protocol")
      assert_empty event.new_values.keys & %w[contact_name company invoice plate vehicle_model request_id]
    end
  end

  test "idempotent repeat compares normalized fields and adds no audit even after slot start" do
    submission = form
    first = CreateBooking.call(submission)
    assert_no_difference [ "Booking.count", "AuditEvent.count" ] do
      travel_to Time.zone.local(first.booking_date.year, first.booking_date.month, first.booking_date.day, 20) do
        repeated = BookingRequest.new(submission.booking_attributes.merge(plate: " abc-1d23 "))
        assert_equal first.id, CreateBooking.call(repeated).id
      end
    end
  end

  test "reusing a request ID with incompatible data returns a conflict" do
    submission = form
    CreateBooking.call(submission)
    changed = BookingRequest.new(submission.booking_attributes.merge(company: "Outra empresa"))
    assert_no_difference [ "Booking.count", "AuditEvent.count" ] do
      assert_nil CreateBooking.call(changed)
      assert changed.errors.of_kind?(:base, :conflict)
    end
  end

  test "failed audit rolls back the booking" do
    AuditEvent.stub(:create!, ->(*) { raise ActiveRecord::RecordInvalid.new(AuditEvent.new) }) do
      assert_no_difference [ "Booking.count", "AuditEvent.count" ] do
        assert_nil CreateBooking.call(form)
      end
    end
  end

  test "rechecks reservations and blocks after acquiring the shared lock" do
    submission = form
    SlotBlock.create!(blocked_date: submission.booking_date, dock_number: 1, slot_number: 1, reason: "Private reason")
    assert_nil CreateBooking.call(submission)
    assert submission.errors.of_kind?(:slot_number, :conflict)
    free = form(slot_number: 2)
    assert CreateBooking.call(free)
    occupied = form(slot_number: 2)
    assert_nil CreateBooking.call(occupied)
    assert occupied.errors.of_kind?(:slot_number, :conflict)
  end

  test "protocol collision retries in a fresh transaction" do
    existing = Booking.create!(booking_attributes(protocol: "DA-#{'A' * 24}"))
    tokens = [ "A" * 24, "B" * 24 ]
    SecureRandom.stub(:hex, ->(*) { tokens.shift }) do
      created = CreateBooking.call(form)
      assert created
      assert_equal "DA-#{'B' * 24}", created.protocol
      refute_equal existing.id, created.id
    end
  end

  test "availability respects active historical and blocked positions without revealing details" do
    date = Date.current + 1
    %w[agendado em_operacao liberado cancelado reagendamento].each_with_index do |status, index|
      insert_booking(booking_date: date, slot_number: index + 1, status: status,
        checkin_at: Time.current, released_at: Time.current, release_remark: "Conferido")
    end
    SlotBlock.create!(blocked_date: date, dock_number: 1, slot_number: 6, reason: "Private reason")
    availability = BookingAvailability.new(date: date, dock_number: 1)
    [ 1, 2, 3, 6 ].each { |slot| assert_not availability.available?(slot) }
    [ 4, 5, 7, 10 ].each { |slot| assert availability.available?(slot) }
    assert BookingAvailability.new(date: date, dock_number: 2).available?(1)
    assert BookingAvailability.new(date: date + 1, dock_number: 1).available?(1)
  end
end
