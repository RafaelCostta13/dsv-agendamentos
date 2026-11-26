require "test_helper"
require_relative "../support/booking_data"

class BookingChangesTest < ActionDispatch::IntegrationTest
  include BookingData
  setup { @authenticated_user = sign_in_as }

  def record(overrides = {})
    Booking.create!(booking_attributes(booking_date: Date.current + 1).merge(overrides))
  end

  def input(booking, overrides = {})
    { booking_date: (Date.current + 2).iso8601, dock_number: "2", slot_number: "3",
      change_reason: "Alteração solicitada.", lock_version: booking.lock_version.to_s }.merge(overrides)
  end

  test "details expose only state compatible management actions and current GETs never write" do
    %w[agendado reagendamento em_operacao liberado cancelado].each_with_index do |status, index|
      booking = record(status: status, dock_number: index + 1, checkin_at: 1.hour.ago, released_at: Time.current, release_remark: "Concluído")
      get admin_booking_path(booking)
      assert_response :success
      expected = booking.schedule_change_allowed? ? 1 : 0
      assert_select "#operational-control a[href*='/edit']", count: expected
      assert_select "#operational-control a[href*='/cancellation']", count: expected
      if status == "reagendamento"
        assert_select "a", text: "Reagendar"
      end
      if expected == 1
        assert_no_difference [ "Booking.count", "AuditEvent.count" ] do
          get edit_admin_booking_path(booking)
          assert_response :success
          assert_select "nav a[aria-current='page']", text: /Agendamentos/
          get cancellation_admin_booking_path(booking)
          assert_response :success
          assert_select "h1", "Cancelar agendamento"
          assert_select "textarea[name='booking[change_reason]'][maxlength='500']"
          assert_select "input[name='booking[lock_version]'][value='0']"
        end
      end
    end
  end

  test "date and dock changes refresh server availability and preserve reason and original version" do
    travel_to Time.zone.local(2026, 11, 25, 14, 30) do
      booking = record
      get edit_admin_booking_path(booking)
      assert_select "button[name='selected_date']", count: 3
      assert_select "button[name='selected_dock']", count: 8
      assert_select "input[name='booking[slot_number]']", count: 10
      assert_select "input[name='booking[slot_number]'][value='1'][checked]:not([disabled])"
      values = input(booking, slot_number: "1", change_reason: "Preservar o motivo preenchido.")
      [ 0, 1, 2, 0, 2 ].each do |offset|
        assert_no_difference "AuditEvent.count" do
          patch reschedule_admin_booking_path(booking), params: { booking: values, selected_date: (Date.current + offset).iso8601 }
        end
        assert_response :success
        assert_select "textarea", text: values[:change_reason]
        assert_select "input[name='booking[lock_version]'][value='0']"
        assert_select "button[name='selected_date'][aria-pressed='true'][value='#{(Date.current + offset).iso8601}']"
        assert_select "input[name='booking[slot_number]'][disabled]", count: offset.zero? ? 7 : 0
        assert_select "input[name='booking[slot_number]'][checked]", count: 0 if offset.zero?
      end
      SlotBlock.create!(blocked_date: Date.current + 2, dock_number: 3, slot_number: 1)
      patch reschedule_admin_booking_path(booking), params: { booking: values, selected_dock: "3" }
      assert_response :success
      assert_select "input[name='booking[slot_number]'][value='1'][disabled]"
      assert_select "input[name='booking[slot_number]'][checked]", count: 0
      assert_select "textarea", text: values[:change_reason]
    end
  end

  test "review compares current and selected positions without writing and final confirmation moves the same booking" do
    booking = record
    values = input(booking)
    before = booking.attributes
    assert_no_difference [ "Booking.count", "AuditEvent.count" ] do
      patch reschedule_admin_booking_path(booking), params: { booking: values, intent: "review" }
    end
    assert_response :success
    assert_select "h2", text: "Agendamento atual"
    assert_select "h2", text: "Novo agendamento"
    assert_select "input[name='booking[change_reason]'][value='#{values[:change_reason]}']"
    assert_select "input[name='booking[lock_version]'][value='0']"
    assert_equal before, booking.reload.attributes
    patch reschedule_admin_booking_path(booking), params: { booking: values, intent: "availability" }
    assert_response :success
    assert_select "textarea", text: values[:change_reason]
    assert_difference "AuditEvent.count", 1 do
      assert_no_difference "Booking.count" do
        patch reschedule_admin_booking_path(booking), params: { booking: values, intent: "confirm" }
      end
    end
    assert_response :see_other
    follow_redirect!
    assert_select "[role='status']", text: "Agendamento alterado com sucesso."
    assert_equal before["protocol"], booking.reload.protocol
    assert_equal Date.current + 2, booking.booking_date
    assert_equal 2, booking.dock_number
    assert_equal 3, booking.slot_number
  end

  test "cancellation preserves the reservation displays its reason and updates matrix and indicators" do
    booking = record
    date = booking.booking_date
    get admin_root_path(date: date.iso8601)
    assert_select "[data-indicator='bookings'] strong", "1"
    patch cancel_admin_booking_path(booking), params: { booking: { change_reason: " Veículo indisponível. ", lock_version: 0 } }
    assert_response :see_other
    follow_redirect!
    assert_select "[role='status']", "Agendamento cancelado com sucesso."
    assert_select "dt", text: "Motivo do cancelamento"
    assert_select "dd", text: "Veículo indisponível."
    assert_select "#operational-control a[href*='/edit'], #operational-control a[href*='/cancellation']", count: 0
    assert_equal "cancelado", booking.reload.status
    get admin_root_path(date: date.iso8601)
    assert_select "[data-indicator='bookings'] strong", "0"
    assert_select "td[data-state='available']", count: 80
    get admin_bookings_path(date: date.iso8601)
    assert_select "td", text: booking.protocol
    assert_select ".admin-status", text: "Cancelado"
  end

  test "awaiting reschedule becomes scheduled and a no op does not update or audit" do
    booking = record(status: "reagendamento")
    get edit_admin_booking_path(booking)
    assert_select "h1", "Reagendar"
    patch reschedule_admin_booking_path(booking), params: { booking: input(booking) }
    assert_response :see_other
    follow_redirect!
    assert_select "[role='status']", "Agendamento reagendado com sucesso."
    booking.reload
    before = booking.attributes
    assert_no_difference "AuditEvent.count" do
      patch reschedule_admin_booking_path(booking), params: { booking: input(booking, slot_number: "3", change_reason: "") }
    end
    assert_response :see_other
    follow_redirect!
    assert_select "[role='status']", "Nenhuma alteração foi realizada."
    assert_equal before, booking.reload.attributes
  end

  test "validation and unavailable destinations preserve input and conflict versions remain obsolete" do
    booking = record
    SlotBlock.create!(blocked_date: Date.current + 2, dock_number: 2, slot_number: 3)
    patch reschedule_admin_booking_path(booking), params: { booking: input(booking) }
    assert_response :conflict
    assert_select "textarea", text: "Alteração solicitada."
    assert_select "input[name='booking[slot_number]'][value='3'][disabled]"
    assert_select "input[name='booking[slot_number]'][checked]", count: 0
    assert_includes response.body, "posição selecionada está bloqueada"
    patch cancel_admin_booking_path(booking), params: { booking: { change_reason: "ab", lock_version: 0 } }
    assert_response :unprocessable_entity
    assert_select "textarea", text: "ab"
    patch cancel_admin_booking_path(booking), params: { booking: { change_reason: "Motivo preservado", lock_version: 9 } }
    assert_response :conflict
    assert_select "textarea", text: "Motivo preservado"
    assert_select "input[name='booking[lock_version]'][value='9']"
    assert_select "input[type='submit'][disabled]"
    assert_equal 0, booking.reload.lock_version
    assert_equal 0, AuditEvent.where(entity_id: booking.id).count
  end

  test "strong parameters prevent state identity personal and operational data manipulation" do
    booking = record
    before = booking.attributes
    attack = { id: 999, status: "liberado", protocol: "ATTACK", request_id: SecureRandom.uuid, operation: "coleta",
      company: "Outra", contact_name: "Outro", invoice: "9", plate: "AAA1234", vehicle_model: "Outro",
      checkin_at: "2000-01-01", released_at: "2000-01-01", release_remark: "ATTACK", created_at: "2000-01-01" }
    patch reschedule_admin_booking_path(booking), params: { booking: input(booking).merge(attack) }
    assert_response :see_other
    kept = before.keys - %w[booking_date dock_number slot_number change_reason lock_version updated_at]
    assert_equal before.slice(*kept), booking.reload.attributes.slice(*kept)
    patch cancel_admin_booking_path(booking), params: { booking: attack.merge(lock_version: 1, change_reason: "Cancelamento solicitado") }
    assert_response :see_other
    assert_equal "cancelado", booking.reload.status
    assert_equal before.slice(*(kept - [ "status" ])), booking.attributes.slice(*(kept - [ "status" ]))
  end

  test "stored XSS reasons remain text and SQL strings cannot choose arbitrary positions" do
    booking = record
    attack = "<script>alert(1)</script>"
    patch reschedule_admin_booking_path(booking), params: { booking: input(booking, change_reason: attack, dock_number: "1 OR 1=1") }
    assert_response :unprocessable_entity
    assert_select "script", count: 0
    assert_select "textarea", text: attack
    refute_includes response.body, attack
    patch cancel_admin_booking_path(booking), params: { booking: { change_reason: attack, lock_version: 0 } }
    assert_response :see_other
    follow_redirect!
    assert_select "script", count: 0
    assert_includes response.body, "&lt;script&gt;"
    refute_includes response.body, attack
    assert_equal 1, Booking.count
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    assert_equal "[FILTERED]", filter.filter({ change_reason: attack })[:change_reason]
  end

  test "invalid states and nonexistent bookings reject direct commands" do
    booking = record(status: "em_operacao", checkin_at: 1.hour.ago)
    [ cancel_admin_booking_path(booking), reschedule_admin_booking_path(booking) ].each do |path|
      patch path, params: { booking: input(booking) }
      assert_response :conflict
    end
    get edit_admin_booking_path(booking)
    assert_response :conflict
    assert_select "button[name='intent'][disabled]"
    patch cancel_admin_booking_path(id: 999999999999), params: { booking: { change_reason: "Motivo", lock_version: 0 } }
    assert_response :not_found
    get edit_admin_booking_path(id: 999999999999)
    assert_response :not_found
  end

  test "CSRF is enabled for cancel and reschedule with restrictive CSP" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    booking = record
    [ cancel_admin_booking_path(booking), reschedule_admin_booking_path(booking) ].each do |path|
      assert_no_difference "AuditEvent.count" do
        patch path, params: { booking: input(booking) }
        assert_response :unprocessable_entity
      end
    end
    get edit_admin_booking_path(booking)
    assert_includes response.headers.fetch("Content-Security-Policy"), "script-src 'none'"
    token = css_select("main .admin-change-form input[name='authenticity_token']").first["value"]
    patch reschedule_admin_booking_path(booking), params: { authenticity_token: token, booking: input(booking) }
    assert_response :see_other
    get cancellation_admin_booking_path(booking)
    token = css_select("main .admin-operation-form input[name='authenticity_token']").first["value"]
    patch cancel_admin_booking_path(booking), params: { authenticity_token: token, booking: { change_reason: "Cancelamento solicitado", lock_version: 1 } }
    assert_response :see_other
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  test "SQL logging redacts the reason in the booking and all audit payloads" do
    booking = record
    original_logger = ActiveRecord::Base.logger
    output = StringIO.new
    ActiveRecord::Base.logger = ActiveSupport::Logger.new(output)
    ActiveRecord::Base.logger.level = Logger::DEBUG
    private_reason = "Motivo privado informado pelo operador"
    patch reschedule_admin_booking_path(booking), params: { booking: input(booking, change_reason: private_reason) }
    assert_response :see_other
    assert_includes output.string, "audit_events"
    assert_includes output.string, "FILTERED"
    refute_includes output.string, private_reason
  ensure
    ActiveRecord::Base.logger = original_logger
  end

  test "production has no management endpoints and GET cannot commit a change" do
    booking = record
    get "/admin/bookings/#{booking.id}/cancel"
    assert_response :not_found
    get "/admin/bookings/#{booking.id}/reschedule"
    assert_response :not_found
    Rails.stub(:env, "production".inquiry) do
      Rails.application.reload_routes!
      { get: %w[edit cancellation], patch: %w[cancel reschedule] }.each do |verb, names|
        names.each do |name|
          assert_raises(ActionController::RoutingError) { Rails.application.routes.recognize_path("/admin/bookings/1/#{name}", method: verb) }
        end
      end
    end
  ensure
    Rails.application.reload_routes!
  end
end
