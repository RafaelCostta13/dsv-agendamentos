require "test_helper"
require_relative "../support/booking_data"

class BookingConstraintsTest < ActiveSupport::TestCase
  include BookingData

  test "protocol and UUID are independently unique in PostgreSQL" do
    original = Booking.find(insert_booking)
    assert_database_rejects ActiveRecord::RecordNotUnique, Booking,
      booking_attributes(protocol: original.protocol, slot_number: 2)
    assert_database_rejects ActiveRecord::RecordNotUnique, Booking,
      booking_attributes(request_id: original.request_id, slot_number: 2)
  end

  test "database rejects missing required booking attributes" do
    %i[protocol request_id booking_date dock_number slot_number operation status contact_name
       company invoice plate vehicle_model lock_version created_at updated_at].each do |field|
      assert_database_rejects ActiveRecord::NotNullViolation, Booking, booking_attributes(field => nil)
    end
  end

  test "database accepts every physical dock and slot boundary" do
    (1..8).each { |dock| insert_booking(dock_number: dock) }
    (2..10).each { |slot| insert_booking(slot_number: slot) }
    assert_equal 17, Booking.count
  end

  test "database rejects out of range docks and slots" do
    [ 0, 9 ].each do |dock|
      assert_database_rejects ActiveRecord::StatementInvalid, Booking, booking_attributes(dock_number: dock)
    end
    [ 0, 11 ].each do |slot|
      assert_database_rejects ActiveRecord::StatementInvalid, Booking, booking_attributes(slot_number: slot)
    end
  end

  test "database accepts both operations and all explicit statuses" do
    Booking::OPERATIONS.each_with_index { |operation, i| insert_booking(operation: operation, slot_number: i + 1) }
    Booking::STATUSES.each_with_index do |status, i|
      insert_booking(status: status, dock_number: 2, slot_number: i + 1,
        checkin_at: Time.utc(2026, 11, 25, 11), released_at: Time.utc(2026, 11, 25, 12),
        release_remark: "Carga conferida")
    end
    assert_equal 7, Booking.count
  end

  test "database rejects unknown operations statuses and negative versions" do
    [ { operation: "descarga" }, { status: "desconhecido" }, { lock_version: -1 } ].each do |invalid|
      assert_database_rejects ActiveRecord::StatementInvalid, Booking, booking_attributes(invalid)
    end
  end

  test "database limits invoice to ASCII digits without discarding zeros" do
    [ "", "12A", "12 3", "-123", "123\n", "١٢٣" ].each do |invoice|
      assert_database_rejects ActiveRecord::StatementInvalid, Booking, booking_attributes(invoice: invoice)
    end
    id = insert_booking(invoice: "0" * 44)
    assert_equal "0" * 44, Booking.find(id).invoice
  end

  test "database enforces varchar lengths" do
    { protocol: 50, contact_name: 80, company: 100, invoice: 44, plate: 7, vehicle_model: 80 }.each do |field, limit|
      assert_database_rejects ActiveRecord::ValueTooLong, Booking, booking_attributes(field => "1" * (limit + 1))
    end
  end

  test "database requires checkin for operations and coherent release timestamps" do
    now = Time.utc(2026, 11, 25, 12)
    [ { status: "em_operacao" }, { released_at: now },
      { checkin_at: now, released_at: now - 1 } ].each do |invalid|
      assert_database_rejects ActiveRecord::StatementInvalid, Booking, booking_attributes(invalid)
    end
    assert insert_booking(checkin_at: now, released_at: now)
  end

  test "released bookings require both timestamps and useful remark length" do
    valid = { status: "liberado", checkin_at: Time.utc(2026, 11, 25, 11),
      released_at: Time.utc(2026, 11, 25, 12), release_remark: "Carga conferida" }
    [ { checkin_at: nil }, { released_at: nil }, { release_remark: nil },
      { release_remark: "ab" }, { release_remark: " \t\n " },
      { release_remark: "  ab\t " }, { release_remark: "x" * 501 } ].each do |invalid|
      assert_database_rejects ActiveRecord::StatementInvalid, Booking, booking_attributes(valid.merge(invalid))
    end
    [ "  abc\t ", "ç" * 500 ].each_with_index do |remark, index|
      assert insert_booking(valid.merge(release_remark: remark, slot_number: index + 1))
    end
  end

  test "scheduled operating and released bookings retain exclusive slot capacity" do
    %w[agendado em_operacao liberado].each_with_index do |status, index|
      attributes = { status: status, dock_number: index + 1, checkin_at: Time.utc(2026, 11, 25, 11),
        released_at: Time.utc(2026, 11, 25, 12), release_remark: "Conferido" }
      insert_booking(attributes)
      assert_database_rejects ActiveRecord::RecordNotUnique, Booking,
        booking_attributes(dock_number: index + 1)
    end
  end

  test "cancelled and rescheduling history permit new bookings in the same position" do
    %w[cancelado reagendamento].each { |status| insert_booking(status: status) }
    assert insert_booking
    assert_equal 3, Booking.count
  end

  test "different docks dates and windows have independent capacity" do
    insert_booking
    assert insert_booking(dock_number: 2)
    assert insert_booking(booking_date: Date.new(2026, 11, 26))
    assert insert_booking(slot_number: 2)
  end

  test "physical occupation is exclusive across all dates and windows" do
    insert_booking(status: "em_operacao", checkin_at: Time.utc(2026, 11, 25, 11))
    assert_database_rejects ActiveRecord::RecordNotUnique, Booking,
      booking_attributes(status: "em_operacao", booking_date: Date.new(2026, 11, 26),
        slot_number: 2, checkin_at: Time.utc(2026, 11, 26, 11))
    assert insert_booking(status: "em_operacao", dock_number: 2, checkin_at: Time.utc(2026, 11, 25, 11))
  end
end
