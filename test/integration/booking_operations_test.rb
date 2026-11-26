require "test_helper"
require_relative "../support/booking_data"

class BookingOperationsTest < ActionDispatch::IntegrationTest
  include BookingData
  setup { @authenticated_user = sign_in_as }

  def scheduled(**attributes)
    Booking.create!(booking_attributes(booking_date: Date.current).merge(attributes))
  end

  test "confirmation GETs are read only and successful PATCHes redirect with a single audit each" do
    travel_to Time.zone.local(2026, 11, 25, 10) do
      booking = scheduled
      get admin_booking_path(booking)
      assert_select "a[href*='confirm_checkin']", text: "Registrar check-in"
      assert_no_difference [ "AuditEvent.count", "Booking.count" ] do
        get confirm_checkin_admin_booking_path(booking)
        assert_response :success
        assert_select "h1", text: "Registrar check-in?"
        assert_select "input[name='booking[lock_version]'][value='0']"
      end
      assert_difference "AuditEvent.count", 1 do
        patch checkin_admin_booking_path(booking, date: Date.current.iso8601), params: { booking: { lock_version: 0 } }
      end
      assert_response :see_other
      follow_redirect!
      assert_select "[role='status']", text: "Check-in registrado com sucesso."
      assert_select "a[href*='confirm_release']", text: "Liberar doca"
      assert_select ".admin-overdue", text: "Em operação — Horário excedido"
      get admin_root_path
      assert_select "td[data-state='em_operacao'] .admin-overdue", text: /Horário excedido/
      get admin_bookings_path
      assert_select ".admin-overdue", text: "Em operação — Horário excedido"
      assert_no_difference "AuditEvent.count" do
        get confirm_release_admin_booking_path(booking)
        assert_response :success
        assert_select "textarea[name='booking[release_remark]']"
      end
      patch release_admin_booking_path(booking), params: { booking: { lock_version: 1, release_remark: " Operação concluída. " } }
      assert_response :see_other
      follow_redirect!
      assert_select "[role='status']", text: "Doca liberada com sucesso."
      assert_select ".admin-overdue", count: 0
      assert_select "a[href*='confirm_checkin'], a[href*='confirm_release']", count: 0
      assert_equal "liberado", booking.reload.status
      assert_equal 2, AuditEvent.where(entity_id: booking.id).count
    end
  end

  test "browser cannot set state timestamps dock date window or protocol in either operation" do
    travel_to Time.zone.local(2026, 11, 25, 10) do
      booking = scheduled
      attack = { status: "cancelado", checkin_at: "2000-01-01", released_at: "2000-01-01", dock_number: 7, booking_date: "2000-01-01", slot_number: 10, protocol: "ATTACK" }
      patch checkin_admin_booking_path(booking), params: { booking: attack.merge(lock_version: 0) }
      assert_response :see_other
      assert_equal Time.current, booking.reload.checkin_at
      assert_equal "em_operacao", booking.status
      assert_nil booking.released_at
      patch release_admin_booking_path(booking), params: { booking: attack.merge(lock_version: 1, release_remark: "Concluído") }
      assert_response :see_other
      assert_equal "liberado", booking.reload.status
      assert_equal Time.current, booking.released_at
      assert_equal 1, booking.dock_number
      assert_equal 1, booking.slot_number
      assert_equal Date.current, booking.booking_date
      refute_equal "ATTACK", booking.protocol
    end
  end

  test "validation and conflicts preserve notes with an obsolete version disabled until reviewing the booking" do
    travel_to Time.zone.local(2026, 11, 25, 10) do
      booking = scheduled(status: "em_operacao", checkin_at: 1.hour.ago)
      patch release_admin_booking_path(booking), params: { booking: { lock_version: 0, release_remark: "ab" } }
      assert_response :unprocessable_entity
      assert_select "textarea", text: "ab"
      assert_select ".admin-field-error", text: /3 a 500/
      patch release_admin_booking_path(booking), params: { booking: { lock_version: 9, release_remark: "Observação preservada" } }
      assert_response :conflict
      assert_select "textarea", text: "Observação preservada"
      assert_select "input[name='booking[lock_version]'][value='9']"
      assert_select "input[type='submit'][disabled]"
      assert_equal "em_operacao", booking.reload.status
    end
  end

  test "wrong dates times occupied docks and invalid states are refused by direct requests" do
    travel_to Time.zone.local(2026, 11, 25, 10) do
      future = scheduled(booking_date: Date.current + 1)
      patch checkin_admin_booking_path(future), params: { booking: { lock_version: 0 } }
      assert_response :unprocessable_entity
      assert_includes response.body, "na data do agendamento"
      occupied = scheduled(booking_date: Date.current - 1, status: "em_operacao", checkin_at: 1.day.ago)
      booking = scheduled
      patch checkin_admin_booking_path(booking), params: { booking: { lock_version: 0 } }
      assert_response :conflict
      assert_includes response.body, "ocupada"
      assert_equal "agendado", booking.reload.status
      assert_equal "em_operacao", occupied.reload.status
      patch release_admin_booking_path(booking), params: { booking: { lock_version: 0, release_remark: "Concluído" } }
      assert_response :conflict
      patch checkin_admin_booking_path(id: 999999999999), params: { booking: { lock_version: 0 } }
      assert_response :not_found
      patch release_admin_booking_path(id: 999999999999), params: { booking: { lock_version: 0, release_remark: "Concluído" } }
      assert_response :not_found
    end
  end

  test "release notes are plain text and request bodies are filtered from logs" do
    travel_to Time.zone.local(2026, 11, 25, 10) do
      booking = scheduled(status: "em_operacao", checkin_at: 1.hour.ago)
      attack = "<script>alert(1)</script>"
      patch release_admin_booking_path(booking), params: { booking: { lock_version: 0, release_remark: attack } }
      assert_response :see_other
      follow_redirect!
      assert_select "script", count: 0
      assert_includes response.body, "&lt;script&gt;"
      refute_includes response.body, attack
      filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      assert_equal "[FILTERED]", filter.filter({ "release_remark" => attack })["release_remark"]
      assert_equal "[FILTERED]", filter.filter({ "booking" => { "release_remark" => attack } })["booking"]
    end
  end

  test "CSRF is enforced for both operational PATCHes and CSP remains restrictive" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    travel_to Time.zone.local(2026, 11, 25, 10) do
      booking = scheduled
      [ checkin_admin_booking_path(booking), release_admin_booking_path(booking) ].each do |path|
        assert_no_difference "AuditEvent.count" do
          patch path, params: { booking: { lock_version: 0, release_remark: "Concluído" } }
          assert_response :unprocessable_entity
        end
      end
      get confirm_checkin_admin_booking_path(booking)
      assert_includes response.headers.fetch("Content-Security-Policy"), "script-src 'none'"
      token = css_select(".admin-operation-form input[name='authenticity_token']").first["value"]
      patch checkin_admin_booking_path(booking), params: { authenticity_token: token, booking: { lock_version: 0 } }
      assert_response :see_other
      get confirm_release_admin_booking_path(booking)
      token = css_select(".admin-operation-form input[name='authenticity_token']").first["value"]
      patch release_admin_booking_path(booking), params: { authenticity_token: token, booking: { lock_version: 1, release_remark: "Concluído" } }
      assert_response :see_other
    end
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  test "repeated requests cannot duplicate audits and matrix and indicators reflect each transition" do
    travel_to Time.zone.local(2026, 11, 25, 10) do
      booking = scheduled
      before = Admin::Dashboard.new(date: Date.current).indicators
      patch checkin_admin_booking_path(booking), params: { booking: { lock_version: 0 } }
      assert_response :see_other
      assert_no_difference "AuditEvent.count" do
        patch checkin_admin_booking_path(booking), params: { booking: { lock_version: 0 } }
        assert_response :conflict
      end
      get admin_root_path
      assert_select "td[data-state='em_operacao'] .admin-overdue", count: 1
      assert_select ".admin-matrix a strong", text: "Em operação — Horário excedido"
      assert_equal before, Admin::Dashboard.new(date: Date.current).indicators
      patch release_admin_booking_path(booking), params: { booking: { lock_version: 1, release_remark: "Concluído" } }
      assert_response :see_other
      released_at = booking.reload.released_at
      assert_no_difference "AuditEvent.count" do
        patch release_admin_booking_path(booking), params: { booking: { lock_version: 1, release_remark: "Não sobrescrever" } }
        assert_response :conflict
      end
      assert_equal "Concluído", booking.reload.release_remark
      assert_equal released_at, booking.released_at
      get admin_root_path
      assert_select "td[data-state='liberado']", count: 1
      assert_select ".admin-overdue", count: 0
      assert_equal before, Admin::Dashboard.new(date: Date.current).indicators
    end
  end

  test "production excludes confirmation and modification routes" do
    Rails.stub(:env, "production".inquiry) do
      Rails.application.reload_routes!
      { get: %w[/admin/bookings/1/confirm_checkin /admin/bookings/1/confirm_release], patch: %w[/admin/bookings/1/checkin /admin/bookings/1/release] }.each do |verb, paths|
        paths.each { |path| assert_raises(ActionController::RoutingError) { Rails.application.routes.recognize_path(path, method: verb) } }
      end
    end
  ensure
    Rails.application.reload_routes!
  end
end
