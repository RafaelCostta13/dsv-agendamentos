require "test_helper"
require_relative "../support/booking_data"

class AuditHistoryTest < ActionDispatch::IntegrationTest
  include BookingData
  setup { @authenticated_user = sign_in_as }

  test "history menu list details and individual timeline show real operations in chronological order" do
    travel_to Time.zone.local(2026, 11, 25, 7) do
      values=booking_attributes.except(:protocol)
      booking=CreateBooking.call(BookingRequest.new(values))
      assert booking
      change=BookingChangeRequest.new(booking_date: Date.current, dock_number: 2, slot_number: 2, change_reason: "Nova doca e horário", lock_version: 0)
      assert ChangeBooking.new(booking_id: booking.id, action: "reschedule", form: change).call
      travel 2.hours
      assert OperateBooking.new(booking_id: booking.id, action: "checkin", lock_version: 1).call
      travel 1.hour
      assert OperateBooking.new(booking_id: booking.id, action: "release", lock_version: 2, release_remark: "Saída sem ocorrências").call
      events=AuditEvent.where(entity_type: "Booking", entity_id: booking.id).order(:created_at, :id).to_a
      assert_equal %w[create reschedule checkin release], events.map(&:action)
      assert_no_difference [ "AuditEvent.count", "Booking.count", "SlotBlock.count" ] do
        get admin_audit_events_path
        assert_response :success
        assert_select ".admin-sidebar a[href='#{admin_audit_events_path}']", count: 0
        assert_select ".admin-audit-table tbody tr", count: 5
        assert_select ".admin-audit-badge", text: /Veículo liberado/
        assert_includes response.body, "Formulário público"
        assert_includes response.body, "Painel administrativo"
        assert_equal "no-store", response.headers["Cache-Control"]
        assert_includes response.headers["Content-Security-Policy"], "script-src 'none'"
        assert_select "script", count: 0
        get admin_booking_path(booking)
        assert_select "#booking-history .admin-audit-timeline > li", count: 4
        labels=css_select("#booking-history h3").map { |element| element.text.strip }
        assert_match(/Agendamento criado/, labels[0])
        assert_match(/Agendamento alterado/, labels[1])
        assert_match(/Check-in realizado/, labels[2])
        assert_match(/Veículo liberado/, labels[3])
        assert_includes response.body, "Saída sem ocorrências"
        get admin_audit_event_path(events.first)
        assert_select ".admin-audit-comparison td", text: "01"
        assert_select ".admin-audit-comparison td", text: "Não registrado"
        get admin_audit_event_path(events[1])
        assert_select ".admin-audit-changed", minimum: 2
        assert_includes response.body, "Nova doca e horário"
      end
    end
  end

  test "date filters use event time in Sao Paulo with exclusive next day and combine with exact normalized protocol" do
    booking=Booking.create!(booking_attributes(protocol: "DA-EXACT", booking_date: Date.new(2026, 12, 1)))
    records=[ Time.utc(2026, 11, 25, 2, 59, 59), Time.utc(2026, 11, 25, 3), Time.utc(2026, 11, 26, 2, 59, 59), Time.utc(2026, 11, 26, 3) ].map do |instant|
      AuditEvent.create!(entity_type: "Booking", entity_id: booking.id, action: "cancel", created_at: instant, reason: instant.iso8601)
    end
    AuditEvent.create!(entity_type: "SlotBlock", entity_id: 555, action: "block", created_at: Time.utc(2026, 11, 25, 4))
    get admin_audit_events_path(start_date: "2026-11-25", end_date: "2026-11-25", event: "cancel", entity_type: "Booking", booking_protocol: "  da-exact  ")
    assert_select ".admin-audit-table tbody tr", count: 2
    assert_includes response.body, records[1].reason
    assert_includes response.body, records[2].reason
    assert_not_includes response.body, records[0].reason
    assert_not_includes response.body, records[3].reason
    get admin_audit_events_path(booking_protocol: "DA-NOT-FOUND")
    assert_select ".admin-empty", text: /Nenhum evento encontrado/
    get admin_audit_events_path(booking_protocol: "DA-EXACT", entity_type: "SlotBlock")
    assert_select ".admin-empty", text: /Nenhum evento encontrado/
    [ { start_date: "bad" }, { end_date: "2026-02-30" }, { start_date: "2026-11-26", end_date: "2026-11-25" }, { entity_type: "Kernel" }, { event: "cancel' OR 1=1 --" }, { booking_protocol: "x"*51 } ].each do |input|
      get admin_audit_events_path(input)
      assert_response :success
      assert_select "[role=alert]", minimum: 1
      assert_select ".admin-audit-table", count: 0
    end
  end

  test "pagination is bounded deterministic and references are grouped without N plus one" do
    bookings=3.times.map { |i| Booking.create!(booking_attributes(protocol: "DA-PAGE-#{i}", slot_number: i+1)) }
    instant=Time.current
    62.times { |i| AuditEvent.create!(entity_type: "Booking", entity_id: bookings[i%3].id, action: "checkin", created_at: instant) }
    queries=[]
    callback=->(*args) { payload=args.last; queries<<payload[:sql] if payload[:sql].match?(/\ASELECT\b/) && payload[:sql].match?(/"(?:audit_events|bookings)"/) }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { get admin_audit_events_path(event: "checkin") }
    assert_equal 4, queries.size, queries.inspect
    assert_select ".admin-audit-table tbody tr", count: 25
    expected=AuditEvent.order(created_at: :desc, id: :desc).limit(25).pluck(:id)
    assert_equal expected, css_select(".admin-audit-table tbody a").map { |a| URI(a["href"]).path.split("/").last.to_i }
    assert_select 'a[rel=next][href*="event=checkin"]'
    get admin_audit_events_path(page: 999999999)
    assert_select ".admin-audit-table tbody tr", count: 13
    get admin_audit_events_path(page: -1)
    assert_select ".admin-audit-table tbody tr", count: 25
    get admin_booking_path(bookings.first, history_page: 999999999)
    assert_select "#booking-history .admin-audit-timeline > li", count: 21
  end

  test "deleted block events keep original positions and reasons with safe details and no invented history" do
    travel_to Time.zone.local(2026, 11, 25, 7) do
      reason="<script>alert(1)</script>"
      assert BlockSlots.new(BlockSelection.new(blocked_date: Date.current+1, dock_numbers: [ 1, 2 ], slot_numbers: [ 10 ], reason: reason)).call
      blocks=SlotBlock.order(:id).to_a
      assert UnblockSlots.new(tokens: blocks.map(&:unlock_token)).call
      assert_equal 0, SlotBlock.count
      get admin_audit_events_path(entity_type: "SlotBlock")
      assert_select ".admin-audit-table tbody tr", count: 4
      assert_select "script", count: 0
      assert_includes response.body, "17:00 - 17:48"
      assert_includes response.body, "26/11/2026"
      event=AuditEvent.find_by!(action: "unblock")
      get admin_audit_event_path(event)
      assert_includes response.body, "&lt;script&gt;"
      assert_not_includes response.body, reason
      assert_select ".admin-audit-comparison td", text: "Não registrado", minimum: 1
      unknown=AuditEvent.create!(entity_type: "Booking", entity_id: 99999999, action: "legacy", previous_values: [ 1, 2 ], new_values: { secret: "HIDDEN", request_id: "PRIVATE" })
      get admin_audit_event_path(unknown)
      assert_response :success
      assert_select "h1", text: "Evento não reconhecido"
      assert_includes response.body, "Origem não registrada"
      assert_includes response.body, "Agendamento não disponível"
      assert_not_includes response.body, "HIDDEN"
      assert_not_includes response.body, "PRIVATE"
    end
  end

  test "multiple no show occurrences and cancellation remain visible and queries cannot modify them" do
    travel_to Time.zone.local(2026, 11, 25, 18) do
      booking=Booking.create!(booking_attributes)
      assert_equal 1, ProcessNoShows.new.call[:processed]
      form=BookingChangeRequest.new(booking_date: Date.current+1, dock_number: 2, slot_number: 1, change_reason: "Reagendado pelo operador", lock_version: booking.reload.lock_version)
      assert ChangeBooking.new(booking_id: booking.id, action: "reschedule", form: form).call
      travel 1.day
      assert_equal 1, ProcessNoShows.new.call[:processed]
      form=BookingChangeRequest.new(change_reason: "Cancelamento final", lock_version: booking.reload.lock_version)
      assert ChangeBooking.new(booking_id: booking.id, action: "cancel", form: form).call
      post login_path, params: { login: { email: @authenticated_user.email, password: "Senha administrativa de teste!" } }
      assert_response :see_other
      assert_no_difference "AuditEvent.count" do
        get admin_booking_path(booking)
        assert_select "#booking-history .admin-audit-timeline > li", count: 4
        assert_select "#booking-history h3", text: /não comparecimento/, count: 2
        assert_select "#booking-history h3", text: /Veículo reagendado/, count: 1
        assert_select "#booking-history h3", text: /Agendamento cancelado/, count: 1
        assert_includes response.body, "Sistema automático"
        assert_includes response.body, "Cancelamento final"
      end
      routes=Rails.application.routes.routes.select { |route| route.defaults[:controller]=="admin/audit_events" }
      assert_equal [ "GET", "GET" ], routes.map(&:verb)
      Rails.stub(:env, ActiveSupport::StringInquirer.new("production")) do
        get admin_audit_events_path
        assert_response :not_found
      end
      get admin_audit_event_path(999999999)
      assert_response :not_found
      get admin_audit_event_path("1-invalid")
      assert_response :not_found
    end
  end
end
