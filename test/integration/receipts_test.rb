require "test_helper"
require_relative "../support/booking_data"

class ReceiptsTest < ActionDispatch::IntegrationTest
  include BookingData
  setup { @authenticated_user = sign_in_as }

  test "confirmed booking renders persisted receipt fields and a private PNG without exposing internal fields" do
    travel_to Time.zone.local(2026, 11, 25, 7) do
      input=submission
      post bookings_path, params: { booking: input }
      assert_response :see_other
      assert_redirected_to booking_confirmation_path
      record=Booking.find_by!(request_id: input[:request_id])
      assert_no_difference [ "Booking.count", "AuditEvent.count" ] do
        follow_redirect!
        assert_select "h1", text: "Agendamento confirmado!"
        assert_select ".protocol", text: record.protocol
        assert_select ".receipt-details dd", text: "26/11/2026"
        assert_select ".receipt-details dd", text: "01"
        assert_select ".receipt-details dd", text: "08:00 às 09:00"
        assert_select ".receipt-details dd", text: record.company
        assert_select ".receipt-details dd", text: record.plate
        assert_select '.receipt-brand img[src*="DSV_Logo"]'
        assert_select '.receipt-qr img[src="/agendar/confirmacao.png"][alt]'
        assert_select 'a[href="/agendar"]', text: "Realizar novo agendamento"
        assert_equal "no-store", response.headers["Cache-Control"]
        assert_includes response.headers["Content-Security-Policy"], "script-src 'none'"
        [ record.contact_name, record.invoice, record.request_id, "lock_version" ].each { |value| assert_not_includes response.body, value }
        get booking_confirmation_path(format: :png)
        assert_response :success
        assert_equal "image/png", response.media_type
        assert_equal "no-store", response.headers["Cache-Control"]
        assert_equal "nosniff", response.headers["X-Content-Type-Options"]
        assert response.body.start_with?("\x89PNG\r\n\x1a\n".b)
        get booking_confirmation_path
        assert_response :success
      end
    end
  end

  test "confirmation is session bound ignores arbitrary identifiers and expires at thirty minutes without sliding" do
    travel_to Time.zone.local(2026, 11, 25, 7) do
      input=submission
      post bookings_path, params: { booking: input }
      record=Booking.find_by!(request_id: input[:request_id])
      other=Booking.create!(booking_attributes(booking_date: Date.current+1, dock_number: 2, company: "Empresa de outra sessão"))
      get booking_confirmation_path(id: other.id, protocol: other.protocol, request_id: other.request_id)
      assert_select ".protocol", text: record.protocol
      assert_not_includes response.body, other.company
      stranger=open_session
      stranger.get booking_confirmation_path(id: record.id, protocol: record.protocol)
      assert_equal 302, stranger.response.status
      stranger.get booking_confirmation_path(format: :png, id: record.id)
      assert_equal 404, stranger.response.status
      travel 29.minutes
      get booking_confirmation_path
      assert_response :success
      travel 1.minute
      get booking_confirmation_path(format: :png)
      assert_response :not_found
      get booking_confirmation_path
      assert_redirected_to new_booking_path
    end
  end

  test "current states and administrative movement are reflected without reactivating cancelled or pending bookings" do
    travel_to Time.zone.local(2026, 11, 25, 7) do
      original=submission
      post bookings_path, params: { booking: original }
      record=Booking.find_by!(request_id: original[:request_id])
      form=BookingChangeRequest.new(booking_date: Date.current+2, dock_number: 3, slot_number: 10, lock_version: 0, change_reason: "Motivo administrativo interno")
      assert ChangeBooking.new(booking_id: record.id, action: "reschedule", form: form).call
      assert_no_difference [ "Booking.count", "AuditEvent.count" ] do
        post bookings_path, params: { booking: original }
        assert_response :see_other
        follow_redirect!
        assert_select ".receipt-details dd", text: "27/11/2026"
        assert_select ".receipt-details dd", text: "03"
        assert_select ".receipt-details dd", text: "17:00 às 17:48"
        assert_not_includes response.body, "Motivo administrativo interno"
      end
      %w[reagendamento cancelado em_operacao liberado].each do |status|
        record.reload.update!(status: status, checkin_at: status.in?(%w[em_operacao liberado]) ? Time.current : nil, released_at: status=="liberado" ? Time.current : nil, release_remark: status=="liberado" ? "Conferido" : nil)
        assert_no_difference [ "Booking.count", "AuditEvent.count" ] do
          post bookings_path, params: { booking: original }
          follow_redirect!
          assert_select ".booking-receipt[data-receipt-state='#{status}']"
          assert_select "h1", text: "Agendamento confirmado!", count: 0
          assert_select ".receipt-qr", count: 0
          get receipt_admin_booking_path(record)
          assert_response :success
          assert_select ".booking-receipt", count: 1
          assert_select ".receipt-qr", count: 0
          get receipt_admin_booking_path(record, format: :png)
          assert_response :not_found
          get booking_confirmation_path(format: :png)
          assert_response :not_found
        end
      end
    end
  end

  test "new booking starts blank with a new request id and revokes previous public receipt context" do
    input=submission
    post bookings_path, params: { booking: input }
    follow_redirect!
    get new_booking_path
    assert_select 'input[name="booking[company]"][value=""]', count: 1
    request_id=css_select('input[name="booking[request_id]"]').first["value"]
    assert_not_equal input[:request_id], request_id
    get booking_confirmation_path
    assert_redirected_to new_booking_path
    assert_equal 1, Booking.where(request_id: input[:request_id]).count
  end

  test "failed creation has no receipt and admin views are escaped restricted and read only" do
    post bookings_path, params: { booking: submission(invoice: "invalid") }
    assert_response :unprocessable_entity
    get booking_confirmation_path
    assert_redirected_to new_booking_path
    record=Booking.create!(booking_attributes(company: "<img src=x onerror=alert(1)>", booking_date: Date.current+1))
    assert_no_difference [ "Booking.count", "AuditEvent.count" ] do
      get admin_booking_path(record)
      assert_select "a[href='#{receipt_admin_booking_path(record)}']", text: "Visualizar comprovante"
      get receipt_admin_booking_path(record)
      assert_response :success
      assert_select ".receipt-details dd", text: record.company
      assert_select "img[onerror], script", count: 0
      assert_includes response.body, "&lt;img"
      assert_select 'img[src*=".png"]', count: 1
      get receipt_admin_booking_path(record, format: :json)
      assert_response :not_acceptable
    end
    Rails.stub(:env, ActiveSupport::StringInquirer.new("production")) do
      get receipt_admin_booking_path(record)
      assert_response :not_found
    end
  end

  test "database failures return a generic uncached receipt error" do
    post bookings_path, params: { booking: submission }
    Booking.stub(:find_by, ->(*) { raise ActiveRecord::ConnectionNotEstablished, "private-password" }) do
      get booking_confirmation_path
      assert_response :service_unavailable
      assert_not_includes response.body, "private-password"
      assert_equal "no-store", response.headers["Cache-Control"]
    end
  end

  private

  def submission(**values)
    booking_attributes(booking_date: Date.current+1).except(:protocol).merge(values)
  end
end
