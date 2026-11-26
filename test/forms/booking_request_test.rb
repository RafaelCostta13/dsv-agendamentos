require "test_helper"

class BookingRequestTest < ActiveSupport::TestCase
  def attributes(overrides = {})
    { contact_name: " João Silva ", company: " Empresa Ágil ", vehicle_model: " Caminhão ",
      invoice: "000123", plate: " abc-1d23 ", operation: "entrega", booking_date: Date.current + 1,
      dock_number: "1", slot_number: "10", request_id: SecureRandom.uuid }.merge(overrides)
  end

  test "normalization preserves invoice zeros and Brazilian plate formats" do
    form = BookingRequest.new(attributes)
    assert form.valid?(:new_booking)
    assert_equal "João Silva", form.contact_name
    assert_equal "Empresa Ágil", form.company
    assert_equal "Caminhão", form.vehicle_model
    assert_equal "000123", form.invoice
    assert_equal "ABC1D23", form.plate
    assert BookingRequest.new(attributes(plate: "abc-1234")).valid?
  end

  test "invalid required and manipulated fields are rejected" do
    { contact_name: " ", company: "A", invoice: "12A", plate: "ABCDE12", vehicle_model: "",
      operation: "outro", booking_date: "invalid", dock_number: "1 OR 1=1", slot_number: "1.5", request_id: "bad" }.each do |field, invalid|
      form = BookingRequest.new(attributes(field => invalid))
      assert_not form.valid?, field.to_s
      assert form.errors[field].any?, field.to_s
    end
  end

  test "field maximum lengths and invoice boundaries are enforced" do
    { contact_name: "n" * 81, company: "c" * 101, vehicle_model: "m" * 81,
      invoice: "1" * 45, plate: "ABC1D234", dock_number: 0, slot_number: 11 }.each do |field, value|
      assert_not BookingRequest.new(attributes(field => value)).valid?
    end
    assert BookingRequest.new(attributes(invoice: "0" * 44)).valid?
  end

  test "booking horizon uses Sao Paulo calendar days including midnight" do
    travel_to Time.zone.local(2026, 11, 25, 7) do
      (0..2).each { |offset| assert BookingRequest.new(attributes(booking_date: Date.current + offset)).valid?(:new_booking) }
      [ -1, 3 ].each { |offset| assert_not BookingRequest.new(attributes(booking_date: Date.current + offset)).valid?(:new_booking) }
    end
    travel_to Time.utc(2026, 11, 26, 2, 59) do
      assert_equal Date.new(2026, 11, 25), Date.current
      assert BookingRequest.new(attributes(booking_date: "2026-11-25", slot_number: 1)).valid?
      assert_not BookingRequest.new(attributes(booking_date: "2026-11-25", slot_number: 1)).valid?(:new_booking)
    end
    travel_to Time.utc(2026, 11, 26, 3) do
      assert_not BookingRequest.new(attributes(booking_date: "2026-11-25")).valid?(:new_booking)
    end
  end

  test "slot start must be strictly later than the server clock" do
    travel_to Time.zone.local(2026, 11, 25, 10) do
      assert_not BookingRequest.new(attributes(booking_date: Date.current, slot_number: 3)).valid?(:new_booking)
      assert BookingRequest.new(attributes(booking_date: Date.current, slot_number: 4)).valid?(:new_booking)
    end
    travel_to Time.zone.local(2026, 11, 25, 17) do
      assert_not BookingRequest.new(attributes(booking_date: Date.current, slot_number: 10)).valid?(:new_booking)
    end
    assert_equal [ "17:00", "17:48" ], AgendaDefinition::SLOT_WINDOWS.fetch(10)
  end

  test "dock choices are restricted by operation" do
    assert AgendaDefinition.dock_numbers_for("entrega").to_a == [ 1, 2, 3 ]
    assert AgendaDefinition.dock_numbers_for("coleta").to_a == [ 4, 5, 6, 7, 8 ]
    assert BookingRequest.new(attributes(operation: "entrega", dock_number: 3)).valid?(:new_booking)
    assert BookingRequest.new(attributes(operation: "coleta", dock_number: 4)).valid?(:new_booking)
    assert_not BookingRequest.new(attributes(operation: "entrega", dock_number: 4)).valid?(:new_booking)
    assert_not BookingRequest.new(attributes(operation: "coleta", dock_number: 3)).valid?(:new_booking)
  end
end
