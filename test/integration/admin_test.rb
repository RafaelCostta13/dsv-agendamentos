require "test_helper"
require_relative "../support/booking_data"

class AdminTest < ActionDispatch::IntegrationTest
  include BookingData
  setup { @authenticated_user = sign_in_as }

  test "dashboard has independent layout logo active menu eighty cells and ten defined windows" do
    travel_to Time.zone.local(2026, 11, 25, 7) do
      get admin_root_path
      assert_response :success
      assert_select "body.admin-body"
      assert_select "header img[src*='DSV_Logo'][alt='DSV']"
      assert_select "nav a[aria-current='page']", text: /Dashboard/
      assert_select ".admin-sidebar a[href='#{new_booking_path}']", text: /Novo agendamento/
      assert_select "input[name='date'][value='2026-11-25']"
      assert_select ".admin-indicator", count: 5
      assert_select ".admin-matrix tbody tr", count: 8
      assert_select ".admin-matrix thead th", count: 11
      assert_select ".admin-matrix tbody td", count: 80
      assert_select ".admin-matrix thead span", text: "17:00 – 17:48"
      assert_select "td[data-state='available']", count: 80
      assert_select "[data-indicator='available'] strong", text: "80"
      assert_select ".admin-legend li", count: 8
      assert_select "script[src*=dashboard_polling][nonce]", count: 1
      assert_match(/script-src 'nonce-[A-Za-z0-9+\/=]+'/, response.headers.fetch("Content-Security-Policy"))
      assert_equal "no-store", response.headers["Cache-Control"]
    end
  end

  test "date queries accept history and future and handle invalid dates safely" do
    travel_to Time.zone.local(2026, 11, 25, 11) do
      { "2026-11-24" => "ended", "2026-12-01" => "outside_horizon", "2026-11-26" => "available" }.each do |date, state|
        get admin_root_path(date: date)
        assert_response :success
        assert_select "input[name='date'][value='#{date}']"
        assert_select "td[data-state='#{state}']", count: 80
        assert_select "a[href='#{admin_bookings_path(date: date)}']", minimum: 1
      end
      [ "invalid", "2026-02-30", "999999999-01-01", "0000-01-01", "20261125", "' OR 1=1--" ].each do |date|
        get admin_root_path(date: date)
        assert_response :success
        assert_select "[role='alert']", text: /Informe uma data válida/
        assert_select "input[name='date'][value='2026-11-25']"
      end
    end
  end

  test "list includes all statuses with deterministic ordering and invoice zeros" do
    date = Date.current + 1
    bookings = %w[reagendamento cancelado liberado em_operacao agendado].each_with_index.map do |status, index|
      Booking.create!(booking_attributes(booking_date: date, slot_number: 5 - index, status: status,
        checkin_at: Time.current, released_at: Time.current, release_remark: "Conferido"))
    end
    get admin_bookings_path
    assert_response :success
    assert_select "nav a[aria-current='page']", text: /Agendamentos/
    assert_select ".admin-bookings-table tbody tr", count: 5
    assert_equal bookings.reverse.map(&:protocol), css_select("tbody tr td:first-child").map(&:text)
    assert_select "td", text: "000123456", count: 5
    assert_select ".admin-status", text: "Reagendamento obrigatório"
    assert_select ".admin-status", text: "Liberado"
    assert_select "thead th", count: 12
  end

  test "all filters are applied on the server and invalid filters return no records" do
    booking = Booking.create!(booking_attributes(booking_date: Date.current + 1, dock_number: 3, operation: "coleta", status: "cancelado"))
    Booking.create!(booking_attributes(booking_date: Date.current + 2))
    get admin_bookings_path(date: booking.booking_date.iso8601, dock_number: "3", operation: "coleta", status: "cancelado")
    assert_response :success
    assert_select "tbody tr", count: 1
    assert_select "td", text: booking.protocol
    [ { date: (Date.current - 1).iso8601 }, { dock_number: "8" }, { operation: "entrega" }, { status: "agendado" } ].each do |different|
      get admin_bookings_path({ date: booking.booking_date.iso8601, dock_number: "3", operation: "coleta", status: "cancelado" }.merge(different))
      assert_select ".admin-empty"
    end
    [ :date, :dock_number, :operation, :status ].each do |field|
      get admin_bookings_path(field => "' OR 1=1; DROP TABLE bookings;--")
      assert_response :success
      assert_select "[role='alert']"
      assert_select ".admin-bookings-table", count: 0
      assert_equal 2, Booking.count
    end
  end

  test "pagination bounds results and retains filters and context through details" do
    date = Date.current + 1
    27.times { Booking.create!(booking_attributes(booking_date: date, status: "cancelado")) }
    query = { date: date.iso8601, dock_number: "1", operation: "entrega", status: "cancelado" }
    get admin_bookings_path(query)
    assert_select "tbody tr", count: 25
    assert_select "a[rel='next'][href='#{admin_bookings_path(query.merge(page: 2))}']"
    get admin_bookings_path(query.merge(page: 2))
    assert_select "tbody tr", count: 2
    assert_select "a[rel='prev'][href='#{admin_bookings_path(query.merge(page: 1))}']"
    details = css_select("tbody a").first["href"]
    get details
    assert_response :success
    assert_select "a[href='#{admin_bookings_path(query.merge(page: '2'))}']", text: "Voltar à lista"
    [ "invalid", "-1", "999999999999999999999999999" ].each do |page|
      get admin_bookings_path(query.merge(page: page))
      assert_response :success
      assert_select "tbody tr", count: 25
    end
    get admin_bookings_path(query.merge(page: "999999999"))
    assert_select "tbody tr", count: 2
  end

  test "details show required data missing operational values and return date" do
    booking = Booking.create!(booking_attributes(booking_date: Date.current + 1, slot_number: 10))
    get admin_booking_path(booking, date: booking.booking_date.iso8601)
    assert_response :success
    [ booking.protocol, booking.contact_name, booking.company, booking.invoice, booking.plate, booking.vehicle_model, "17:00", "17:48" ].each do |value|
      assert_includes response.body, value
    end
    assert_select "dd", text: "Não registrado", count: 4
    assert_select "a[href='#{admin_root_path(date: booking.booking_date.iso8601)}']", text: "Voltar ao Dashboard"
    assert_select "main form", count: 0
    assert_select "a[data-method], a[data-turbo-method]", count: 0
    get admin_booking_path(id: "999999999999")
    assert_response :not_found
  end

  test "stored HTML in all user content is escaped in list dashboard and details" do
    attack = "<script>alert(1)</script>"
    booking = Booking.create!(booking_attributes(booking_date: Date.current + 1, status: "liberado",
      contact_name: attack, company: attack, vehicle_model: attack, protocol: attack,
      checkin_at: Time.current, released_at: Time.current, release_remark: attack, change_reason: attack))
    [ admin_root_path(date: booking.booking_date.iso8601), admin_bookings_path, admin_booking_path(booking) ].each do |path|
      get path
      assert_response :success
      assert_select "script", count: path == admin_root_path(date: booking.booking_date.iso8601) ? 1 : 0
      assert_select "script:not([src])", count: 0
      assert_select "[onerror], [onclick]", count: 0
      refute_includes response.body, attack
    end
    assert_includes response.body, "&lt;script&gt;"
  end

  test "admin routes expose only read actions and controller refuses production" do
    booking = Booking.create!(booking_attributes)
    [ [ :post, "/admin/bookings" ], [ :patch, "/admin/bookings/#{booking.id}" ], [ :delete, "/admin/bookings/#{booking.id}" ] ].each do |verb, path|
      assert_no_difference [ "Booking.count", "AuditEvent.count", "SlotBlock.count" ] do
        public_send(verb, path)
        assert_response :not_found
      end
    end
    Rails.stub(:env, "production".inquiry) do
      [ "/admin", "/admin/bookings", "/admin/bookings/#{booking.id}" ].each do |path|
        get path
        assert_response :not_found
      end
    end
  end

  test "production route loading excludes all admin endpoints" do
    Rails.stub(:env, "production".inquiry) do
      Rails.application.reload_routes!
      assert_equal "home", Rails.application.routes.recognize_path("/", method: :get).fetch(:controller)
      [ "/admin", "/admin/bookings", "/admin/bookings/1" ].each do |path|
        assert_raises(ActionController::RoutingError) { Rails.application.routes.recognize_path(path, method: :get) }
      end
    end
  ensure
    Rails.application.reload_routes!
  end
  test "database failures return a generic uncached page without SQL or infrastructure details" do
    internal = "SELECT private_column FROM bookings; internal_db_address"
    Admin::Dashboard.stub(:new, ->(**) { raise ActiveRecord::StatementInvalid, internal }) do
      get admin_root_path
      assert_response :service_unavailable
      assert_select "h1", text: "Consulta indisponível"
      refute_includes response.body, internal
      refute_includes response.body, "ActiveRecord"
      assert_equal "no-store", response.headers["Cache-Control"]
    end
  end

  test "missing reservation has a Portuguese error and a working list return" do
    get admin_booking_path(id: "999999999999", date: "2026-11-25")
    assert_response :not_found
    assert_select "h1", text: "Agendamento não encontrado"
    assert_select "a[href='#{admin_bookings_path(date: "2026-11-25")}']", text: "Voltar à lista"
  end
end
