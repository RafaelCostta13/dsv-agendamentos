require "test_helper"
require_relative "../support/booking_data"

class DashboardRefreshTest < ActionDispatch::IntegrationTest
  include BookingData
  setup { @authenticated_user = sign_in_as }

  test "initial dashboard and fragment share one renderer with a server timestamp and scoped CSP" do
    travel_to Time.zone.local(2026, 11, 25, 14, 35, 5) do
      get admin_root_path(date: "2026-11-27")
      assert_response :success
      assert_select "#dashboard-polling[data-interval='5000'][data-timeout='10000'][data-max-retry='30000']"
      assert_select "[data-polling-time]", text: "14:35:05"
      initial = css_select("#dashboard-data").first.to_html
      nonce = css_select("script[src*=dashboard_polling]").first["nonce"]
      assert_includes response.headers["Content-Security-Policy"], "script-src 'nonce-#{nonce}'"
      refute_match(/unsafe-inline|unsafe-eval/, response.headers["Content-Security-Policy"])
      get admin_dashboard_refresh_path(date: "2026-11-27")
      assert_response :success
      assert_equal initial, css_select("#dashboard-data").first.to_html
      assert_equal "no-store", response.headers["Cache-Control"]
      assert_select "#dashboard-data[data-date='2026-11-27'][data-updated-at='2026-11-25T14:35:05-03:00']"
      assert_select "header, nav.admin-sidebar, #dashboard-date-form, script", count: 0
      refute_match(/<!doctype|<html|<body/i, response.body)
      assert_includes response.headers["Content-Security-Policy"], "script-src 'none'"
      get admin_bookings_path
      assert_select "script", count: 0
      assert_includes response.headers["Content-Security-Policy"], "script-src 'none'"
    end
  end

  test "refresh rejects malformed or missing dates and hides database failures" do
    [ nil, "bad", "2026-02-30", "' OR 1=1 --", "0000-01-01" ].each do |date|
      get admin_dashboard_refresh_path(date: date)
      assert_response :unprocessable_entity
      assert_select "#dashboard-data", count: 0
    end
    failure = ->(*) { raise ActiveRecord::ConnectionNotEstablished, "private-password" }
    Admin::Dashboard.stub(:new, failure) do
      get admin_dashboard_refresh_path(date: "2026-11-25")
      assert_response :service_unavailable
      assert_not_includes response.body, "private-password"
      assert_select "#dashboard-data", count: 0
    end
    Rails.stub(:env, ActiveSupport::StringInquirer.new("production")) do
      get admin_dashboard_refresh_path(date: "2026-11-25")
      assert_response :not_found
    end
  end

  test "independent dashboard sessions retain their selected dates with grouped read performance" do
    travel_to Time.zone.local(2026, 11, 25, 7) do
      Booking.create!(booking_attributes(booking_date: Date.current+1))
      sessions = [ open_session, open_session ]
      sessions.each do |session|
        session.post login_path, params: { login: { email: @authenticated_user.email, password: "Senha administrativa de teste!" } }
        session.assert_response :see_other
      end
      samples = []
      sessions.each_with_index do |session, index|
        3.times do
          date = Date.current+index+1
          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          session.get admin_dashboard_refresh_path(date: date.iso8601)
          samples << (Process.clock_gettime(Process::CLOCK_MONOTONIC)-started)*1000
          session.assert_response :success
          session.assert_select "#dashboard-data[data-date='#{date.iso8601}']"
          session.assert_select "[data-indicator=bookings] strong", text: index.zero? ? "1" : "0"
        end
      end
      File.write(Rails.root.join("tmp/rf009-http-performance.json"), JSON.generate(sessions: 2, requests: samples.size, min_ms: samples.min.round(2), max_ms: samples.max.round(2)))
    end
  end

  test "polling reflects creation operations moves cancellation blocking and no show without write side effects" do
    travel_to Time.zone.local(2026, 11, 25, 7) do
      date=Date.current
      refresh(date)
      assert_select "[data-indicator=available] strong", text: "80"
      values=booking_attributes.except(:protocol)
      record=CreateBooking.call(BookingRequest.new(values))
      assert record
      refresh(date)
      assert_select "td[data-state=agendado]", count: 1
      assert_select "[data-indicator=available] strong", text: "79"
      travel 1.hour
      assert OperateBooking.new(booking_id: record.id, action: "checkin", lock_version: 0).call
      refresh(date)
      assert_select "td[data-state=em_operacao]", count: 1
      assert OperateBooking.new(booking_id: record.id, action: "release", lock_version: 1, release_remark: "Conferido").call
      refresh(date)
      assert_select "td[data-state=liberado]", count: 1
      assert_select "[data-indicator=bookings] strong", text: "1"
      moved=Booking.create!(booking_attributes(booking_date: date+1, slot_number: 2))
      form=BookingChangeRequest.new(booking_date: date+2, dock_number: 2, slot_number: 3, change_reason: "Nova posição", lock_version: 0)
      assert ChangeBooking.new(booking_id: moved.id, action: "reschedule", form: form).call
      refresh(date+1)
      assert_select "td[data-state=agendado]", count: 0
      refresh(date+2)
      assert_select "td[data-state=agendado] a[href*='/#{moved.id}']", count: 1
      form=BookingChangeRequest.new(change_reason: "Cancelado pelo operador", lock_version: 1)
      assert ChangeBooking.new(booking_id: moved.id, action: "cancel", form: form).call
      refresh(date+2)
      assert_select "td[data-state=available]", count: 80
      assert BlockSlots.new(BlockSelection.new(blocked_date: date+1, dock_numbers: [ 3 ], slot_numbers: [ 1 ], reason: "Manutenção")).call
      refresh(date+1)
      assert_select "td[data-state=blocked]", count: 1
      block=SlotBlock.find_by!(blocked_date: date+1)
      assert UnblockSlots.new(tokens: [ block.unlock_token ]).call
      refresh(date+1)
      assert_select "td[data-state=available]", count: 80
      missing=Booking.create!(booking_attributes(slot_number: 10))
      travel_to Time.zone.local(2026, 11, 25, 17, 30)
      refresh(date)
      assert_equal "agendado", missing.reload.status
      assert_equal 1, ProcessNoShowsJob.perform_now[:processed]
      refresh(date)
      assert_select "[data-indicator=pending_reschedules] strong", text: "1"
      assert_select "td[data-state=em_operacao]", count: 0
      assert_select "td[data-state=liberado]", count: 1
      form=BookingChangeRequest.new(booking_date: date+1, dock_number: 2, slot_number: 1, change_reason: "Reagendamento", lock_version: missing.reload.lock_version)
      assert ChangeBooking.new(booking_id: missing.id, action: "reschedule", form: form).call
      refresh(date+1)
      assert_select "[data-indicator=pending_reschedules] strong", text: "0"
      assert_select "td[data-state=agendado]", count: 1
    end
  end

  test "each poll recalculates time without changing records and preserves historical and future consultation" do
    travel_to Time.zone.local(2026, 11, 25, 8, 59, 59) do
      scheduled=Booking.create!(booking_attributes)
      operation=Booking.create!(booking_attributes(dock_number: 2, status: "em_operacao", checkin_at: Time.current))
      refresh(Date.current)
      assert_select ".admin-overdue", count: 0
      travel 1.second
      refresh(Date.current)
      assert_select ".admin-overdue", count: 2
      assert_select "td[data-state=ended]", minimum: 1
      assert_equal "agendado", scheduled.reload.status
      assert_equal "em_operacao", operation.reload.status
      travel_to Time.zone.local(2026, 11, 25, 17, 48)
      Session.where(revoked_at: nil).update_all(last_seen_at: Time.current)
      refresh(Date.current)
      assert_select "td[data-state=available]", count: 0
      refresh(Date.current+1)
      assert_select "td[data-state=available]", count: 80
      refresh(Date.current-5)
      assert_select "td[data-state=ended]", count: 80
      refresh(Date.current+20)
      assert_select "td[data-state=outside_horizon]", count: 80
    end
    travel_to Time.utc(2026, 11, 26, 3) do
      Session.where(revoked_at: nil).update_all(last_seen_at: Time.current)
      refresh(Date.new(2026, 11, 26))
      assert_select "td[data-state=available]", count: 80
      assert_select "#dashboard-data[data-updated-label='00:00:00']"
    end
  end

  test "escaped content stays inert and each complete update uses only three grouped reads" do
    travel_to Time.zone.local(2026, 11, 25, 7) do
      record=Booking.create!(booking_attributes(protocol: "<img src=x onerror=alert(1)>"))
      SlotBlock.create!(blocked_date: Date.current, dock_number: 2, slot_number: 1, reason: "<script>alert(2)</script>")
      queries=[]
      callback=->(*args) { payload=args.last; queries<<payload[:sql] if payload[:sql].match?(/\ASELECT\b/i) && payload[:sql].match?(/"(?:bookings|slot_blocks)"/) }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { get admin_dashboard_refresh_path(date: Date.current.iso8601) }
      assert_response :success
      assert_equal 3, queries.size, queries.inspect
      assert_select "script, img[onerror]", count: 0
      assert_select "a[title='<script>alert(2)</script>']", count: 1
      assert_not_includes response.body, record.company
    end
  end

  private

  def refresh(date)
    assert_no_difference [ "Booking.count", "SlotBlock.count", "AuditEvent.count" ] do
      get admin_dashboard_refresh_path(date: date.iso8601)
      assert_response :success
    end
  end
end
