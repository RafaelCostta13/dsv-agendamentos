require "test_helper"
require_relative "../support/booking_data"

class NoShowsTest < ActionDispatch::IntegrationTest
  include BookingData
  setup { @authenticated_user = sign_in_as }

  test "late arrivals show attention in matrix list and details without GET side effects" do
    travel_to Time.zone.local(2026, 11, 25, 11, 20) do
      record=Booking.create!(booking_attributes(slot_number: 3))
      snapshot=record.attributes
      assert_no_difference "AuditEvent.count" do
        get admin_root_path
        assert_response :success
        assert_select ".admin-matrix .admin-overdue", text: /Chegada atrasada/
        get admin_bookings_path
        assert_select ".admin-status.admin-overdue", text: "Agendado — Chegada atrasada"
        get admin_booking_path(record)
        assert_select ".admin-status.admin-overdue", text: "Agendado — Chegada atrasada", count: 2
        assert_select "a", text: "Registrar check-in"
      end
      assert_equal snapshot, record.reload.attributes
    end
  end

  test "global pending card links to all dates and reuses reschedule details while retaining original indicators" do
    travel_to Time.zone.local(2026, 11, 25, 18) do
      records=[ -7, -1, 0 ].each_with_index.map { |offset, index| Booking.create!(booking_attributes(booking_date: Date.current+offset, slot_number: index+1)) }
      future=Booking.create!(booking_attributes(booking_date: Date.current+1))
      assert_equal 3, ProcessNoShowsJob.perform_now[:processed]
      get admin_root_path(date: (Date.current+1).iso8601)
      assert_select "[data-indicator=bookings] strong", text: "1"
      assert_select "[data-indicator=available] strong", text: "79"
      assert_select "[data-indicator=deliveries] strong", text: "1"
      assert_select "[data-indicator=pickups] strong", text: "0"
      assert_select "[data-indicator=pending_reschedules] strong", text: "3"
      path=admin_bookings_path(status: "reagendamento")
      assert_select "[data-indicator=pending_reschedules] a[href='#{path}']"
      get path
      assert_select "tbody tr", count: 3
      assert_select "td p", text: ProcessNoShows::REASON, count: 3
      get admin_booking_path(records.first)
      assert_select ".admin-alert", text: /Reagendamento obrigatório.*nova data/
      assert_select "a", text: "Reagendar"
      assert_select "a", text: "Cancelar agendamento"
      assert_select "a", text: "Registrar check-in", count: 0
      assert_includes response.body, ProcessNoShows::REASON
      get new_booking_path
      assert_not_includes response.body, ProcessNoShows::REASON
      assert_includes response.headers["Content-Security-Policy"], "script-src 'none'"
      assert_equal "agendado", future.reload.status
      form=BookingChangeRequest.new(booking_date: Date.current+1, dock_number: 2, slot_number: 1, change_reason: "Nova posição", lock_version: records.first.reload.lock_version)
      assert ChangeBooking.new(booking_id: records.first.id, action: "reschedule", form: form).call
      get admin_root_path
      assert_select "[data-indicator=pending_reschedules] strong", text: "2"
    end
  end

  test "GET requests never process eligible no shows and no processing endpoint exists" do
    travel_to Time.zone.local(2026, 11, 25, 18) do
      record=Booking.create!(booking_attributes)
      assert_no_difference "AuditEvent.count" do
        [ admin_root_path, admin_bookings_path, admin_booking_path(record), new_booking_path ].each { |path| get path; assert_response :success }
      end
      assert_equal "agendado", record.reload.status
      assert_empty Rails.application.routes.routes.select { |route| route.defaults[:controller].to_s.include?("no_show") }
    end
  end
end
