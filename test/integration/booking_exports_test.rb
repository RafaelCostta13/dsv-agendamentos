require "test_helper"
require_relative "../support/booking_data"
require_relative "../support/xlsx_reader"

class BookingExportsTest < ActionDispatch::IntegrationTest
  include BookingData
  include XlsxReader
  setup { @authenticated_user = sign_in_as }

  test "export shares period dock operation and status filters and ignores pagination" do
    date=Date.new(2026, 11, 1)
    32.times { |i| Booking.create!(booking_attributes(booking_date: date+i, operation: "coleta", status: "cancelado", dock_number: 3)) }
    Booking.create!(booking_attributes(booking_date: date, operation: "entrega", status: "cancelado", dock_number: 3))
    query={ start_date: "2026-11-01", end_date: "2026-11-30", dock_number: "3", operation: "coleta", status: "cancelado" }
    get admin_bookings_path(query)
    assert_response :success
    assert_select ".admin-bookings-table tbody tr", count: 25
    assert_select 'a.admin-button-export[href*="start_date=2026-11-01"]'
    assert_select 'a.admin-button-export[href*="page="]', count: 0
    assert_select 'input[name=start_date][value="2026-11-01"]'
    assert_no_difference [ "Booking.count", "SlotBlock.count" ] do
      assert_difference "AuditEvent.count", 1 do
      get export_admin_bookings_path(query.merge(page: 2, per_page: 1, format: :xlsx))
      assert_response :success
      assert_equal ExportBookingsXlsx::MIME_TYPE, response.media_type
      assert_equal "no-store", response.headers["Cache-Control"]
      assert_includes response.headers["Content-Disposition"], "attachment"
      assert_includes response.headers["Content-Disposition"], "agendamentos_2026-11-01_a_2026-11-30.xlsx"
      with_xlsx(response.body) do |book|
        assert_equal 31, book.last_row
        assert_equal Date.new(2026, 11, 1), book.cell(2, 10)
        assert_equal Date.new(2026, 11, 30), book.cell(31, 10)
        assert_equal "Coleta", book.cell(2, 6)
      end
      end
    end
  end

  test "individual dates stay compatible and a period takes priority over a preselected date" do
    Booking.create!(booking_attributes(booking_date: Date.new(2026, 11, 1)))
    Booking.create!(booking_attributes(booking_date: Date.new(2026, 11, 2)))
    get export_admin_bookings_path(date: "2026-11-01")
    assert_response :success
    assert_includes response.headers["Content-Disposition"], "agendamentos_2026-11-01.xlsx"
    with_xlsx(response.body) { |book| assert_equal 2, book.last_row }
    get export_admin_bookings_path(date: "2026-11-01", start_date: "2026-11-01", end_date: "2026-11-02")
    assert_response :success
    with_xlsx(response.body) { |book| assert_equal 3, book.last_row }
  end

  test "invalid empty and failed exports show safe HTML with filters preserved and no partial attachment" do
    [ { start_date: "2026-11-30", end_date: "2026-11-01" }, { start_date: "invalid" }, { end_date: "2026-02-30" }, { dock_number: "1 OR 1=1" }, { status: "invalid" } ].each do |query|
      get export_admin_bookings_path(query)
      assert_response :unprocessable_entity
      assert_equal "text/html", response.media_type
      assert_select "[role=alert]", minimum: 1
      assert_nil response.headers["Content-Disposition"]
    end
    get export_admin_bookings_path(start_date: "2026-11-01")
    assert_response :unprocessable_entity
    assert_includes response.body, "Nenhum agendamento encontrado"
    assert_select 'input[name=start_date][value="2026-11-01"]'
    failure=->(*) { raise StandardError, "private-server-path" }
    ExportBookingsXlsx.stub(:new, failure) do
      get export_admin_bookings_path
      assert_response :service_unavailable
      assert_not_includes response.body, "private-server-path"
      assert_nil response.headers["Content-Disposition"]
    end
    Rails.stub(:env, ActiveSupport::StringInquirer.new("production")) do
      get export_admin_bookings_path
      assert_response :not_found
    end
  end
end
