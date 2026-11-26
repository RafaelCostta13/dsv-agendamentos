require "test_helper"
require_relative "../support/booking_data"

class BookingsTest < ActionDispatch::IntegrationTest
  include BookingData

  def submission(overrides = {})
    booking_attributes(booking_date: Date.current + 1).except(:protocol).merge(overrides)
  end

  test "public form uses server-rendered native inputs and a restrictive CSP" do
    get new_booking_path
    assert_response :success
    assert_select "form[action='#{bookings_path}'][method='post']", count: 1
    assert_select "input[name='booking[operation]']", count: 2
    assert_select "input[name='booking[booking_date]'][type='hidden']", count: 1
    assert_select "button[name='selected_date'][formnovalidate][formaction='#{bookings_path(anchor: "schedule")}']", count: 3
    assert_select "button[name='intent'][value='availability'][formaction='#{bookings_path(anchor: "schedule")}']"
    assert_select "section#schedule[aria-labelledby='schedule-heading']", count: 1
    assert_select "input[name='booking[dock_number]']", count: 8
    assert_select ".dock-card[data-operations='entrega']", count: 3
    assert_select ".dock-card[data-operations='coleta']", count: 5
    assert_select "input[name='booking[slot_number]']", count: 10
    assert_select "input[name='booking[invoice]'][type='text'][inputmode='numeric']"
    assert_select "script", count: 0
    assert_includes response.headers.fetch("Content-Security-Policy"), "script-src 'none'"
  end

  test "creates and redirects to a private-session operational confirmation without an ID lookup" do
    assert_difference [ "Booking.count", "AuditEvent.count" ], 1 do
      post bookings_path, params: { booking: submission }
    end
    assert_response :see_other
    assert_redirected_to booking_confirmation_path
    follow_redirect!
    assert_response :success
    assert_select "h1", "Agendamento confirmado!"
    assert_select ".protocol", Booking.order(:id).last.protocol
    assert_includes response.body, "Empresa de teste"
    stranger = open_session
    stranger.get booking_confirmation_path
    assert_equal 302, stranger.response.status
    assert_select "a", text: "Realizar novo agendamento"
  end

  test "availability refresh preserves fields and UUID without putting personal data in the URL" do
    input = submission(contact_name: "João", company: "Empresa", invoice: "00001")
    post bookings_path, params: { booking: input, intent: "availability" }
    assert_response :success
    %i[contact_name company invoice request_id].each do |field|
      assert_select "input[name='booking[#{field}]'][value='#{input.fetch(field)}']"
    end
    assert_select "input[name='booking[dock_number]'][value='1'][checked]"
    assert_select "input[name='booking[slot_number]'][value='1'][checked]"
    SlotBlock.create!(blocked_date: input[:booking_date], dock_number: 1, slot_number: 1, reason: "Private reason")
    post bookings_path, params: { booking: input, intent: "availability" }
    assert_select "input[name='booking[slot_number]'][value='1'][disabled]"
    assert_select "input[name='booking[slot_number]'][checked]", count: 0
    refute_includes response.body, "Private reason"
    post bookings_path, params: { booking: input.merge(dock_number: 2), intent: "availability" }
    assert_select "input[name='booking[slot_number]'][value='1'][disabled]", count: 0
    post bookings_path, params: { booking: input.merge(booking_date: Date.current + 2), intent: "availability" }
    assert_select "input[name='booking[slot_number]'][value='1'][disabled]", count: 0
  end

  test "public input cannot set internal operational fields" do
    post bookings_path, params: { booking: submission(status: "liberado", protocol: "ATTACK",
      checkin_at: Time.current, released_at: Time.current, lock_version: 99) }
    assert_response :see_other
    booking = Booking.order(:id).last
    assert_equal "agendado", booking.status
    refute_equal "ATTACK", booking.protocol
    assert_nil booking.checkin_at
    assert_nil booking.released_at
    assert_equal 0, booking.lock_version
  end

  test "rejects a dock that does not match the selected operation" do
    assert_no_difference "Booking.count" do
      post bookings_path, params: { booking: submission(operation: "entrega", dock_number: 4) }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Selecione uma doca disponível para esta operação."
  end

  test "XSS and SQL strings are escaped and cannot change database structure" do
    attack = "<script>alert(1)</script>"
    input = submission(contact_name: attack, company: "'; DROP TABLE bookings;--", invoice: "invalid")
    assert_no_difference "Booking.count" do
      post bookings_path, params: { booking: input }
    end
    assert_response :unprocessable_entity
    assert_select "script", count: 0
    assert_includes response.body, "&lt;script&gt;"
    assert ActiveRecord::Base.connection.table_exists?(:bookings)
    stored = submission(contact_name: attack)
    post bookings_path, params: { booking: stored }
    assert_response :see_other
    follow_redirect!
    assert_select "script", count: 0
    refute_includes response.body, attack
  end

  test "invalid data and an unavailable position preserve input with Portuguese errors" do
    input = submission(booking_date: Date.current + 3, dock_number: 9, slot_number: 11)
    assert_no_difference "Booking.count" do
      post bookings_path, params: { booking: input }
    end
    assert_response :unprocessable_entity
    assert_select ".form-errors"
    assert_select "input[name='booking[company]'][value='Empresa de teste']"
    SlotBlock.create!(blocked_date: Date.current + 1, dock_number: 1, slot_number: 1)
    post bookings_path, params: { booking: submission }
    assert_response :conflict
    assert_includes response.body, "Este horário não está mais disponível."
  end

  test "CSRF is enforced when protection is explicitly enabled" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    get new_booking_path
    assert_select "input[name='authenticity_token']"
    assert_no_difference "Booking.count" do
      post bookings_path, params: { booking: submission }
      assert_response :unprocessable_entity
    end
    # A new GET provides the token tied to this browser session.
    get new_booking_path
    token = css_select("input[name='authenticity_token']").first["value"]
    post bookings_path, params: { booking: submission, authenticity_token: token }
    assert_response :see_other
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  test "date cards refresh availability immediately preserving data through repeated switches" do
    travel_to Time.zone.local(2026, 11, 25, 11, 30) do
      input = submission(slot_number: 1)
      [ 0, 1, 2, 0, 2, 1 ].each do |offset|
        date = Date.current + offset
        assert_no_difference [ "Booking.count", "AuditEvent.count" ] do
          post bookings_path, params: { booking: input, selected_date: date.iso8601 }
        end
        assert_response :success
        assert_select "button[name='selected_date'][value='#{date.iso8601}'][aria-pressed='true']"
        assert_select "input[name='booking[booking_date]'][value='#{date.iso8601}']"
        input.except(:booking_date, :slot_number).each do |field, value|
          assert_select "input[name='booking[#{field}]'][value='#{value}']"
        end
        assert_select "input[name='booking[slot_number]'][disabled]", count: offset.zero? ? 4 : 0
        assert_select "input[name='booking[slot_number]'][checked]", count: offset.zero? ? 0 : 1
      end
    end
  end

  test "after 17 date changes enable future slots and confirmation accepts an early future window" do
    travel_to Time.zone.local(2026, 11, 25, 17, 30) do
      [ 0, 1, 2 ].each do |offset|
        post bookings_path, params: { booking: submission, selected_date: (Date.current + offset).iso8601 }
        assert_response :success
        assert_select "input[name='booking[slot_number]'][disabled]", count: offset.zero? ? 10 : 0
      end
      assert_difference [ "Booking.count", "AuditEvent.count" ], 1 do
        post bookings_path, params: { booking: submission(slot_number: 1) }
      end
      assert_response :see_other
      assert_equal Date.current + 1, Booking.order(:id).last.booking_date
      assert_equal 1, Booking.order(:id).last.slot_number
    end
  end

  test "date card requests reject invalid horizons and clear a selection blocked on the new date" do
    travel_to Time.zone.local(2026, 11, 25, 11, 30) do
      SlotBlock.create!(blocked_date: Date.current + 2, dock_number: 1, slot_number: 1)
      [ (Date.current - 1).iso8601, (Date.current + 3).iso8601, "invalid", (Date.current + 2).iso8601 ].each do |date|
        post bookings_path, params: { booking: submission, selected_date: date }
        assert_response :success
        assert_select "input[name='booking[slot_number]'][checked]", count: 0
        assert_select "input[name='booking[slot_number]'][value='1'][disabled]"
      end
    end
  end
end
