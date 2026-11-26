require "test_helper"
require_relative "../support/booking_data"

class AuthorizationTest < ActionDispatch::IntegrationTest
  include BookingData

  test "unauthenticated HTML redirects while polling receives 401" do
    get admin_root_path
    assert_redirected_to login_path
    get admin_dashboard_refresh_path(date: Date.current.iso8601)
    assert_response :unauthorized
  end

  test "viewer reads operations but direct writes and user management return 403" do
    sign_in_as(role: "viewer")
    booking = Booking.create!(booking_attributes(booking_date: Date.current + 1))
    get admin_root_path
    assert_response :success
    get admin_booking_path(booking)
    assert_response :success
    assert_select "a", text: /Registrar check-in|Alterar agendamento|Cancelar agendamento/, count: 0
    get admin_slot_blocks_path
    assert_response :success
    assert_select "#block-selection", count: 0
    patch checkin_admin_booking_path(booking), params: { booking: { lock_version: 0 } }
    assert_response :forbidden
    post admin_slot_blocks_path, params: { slot_block: { blocked_date: Date.current + 1, dock_numbers: [ 1 ], slot_numbers: [ 1 ] } }
    assert_response :forbidden
    get admin_users_path
    assert_response :forbidden
    assert_equal "agendado", booking.reload.status
  end

  test "operator performs operational routes but cannot manage users or see user audit" do
    sign_in_as(role: "operator")
    booking = Booking.create!(booking_attributes(booking_date: Date.current, slot_number: 10))
    get confirm_checkin_admin_booking_path(booking)
    assert_response :success
    get admin_users_path
    assert_response :forbidden
    event = AuditEvent.find_by!(action: "login_success")
    get admin_audit_event_path(event)
    assert_response :forbidden
    get admin_audit_events_path
    assert_response :success
    assert_select "option[value=User]", count: 0
  end

  test "administrator receives user management and profile access" do
    user = sign_in_as(role: "admin")
    get admin_users_path
    assert_response :success
    get admin_profile_path
    assert_response :success
    assert_select "dd", text: user.email
    assert_select "nav a", text: /Usuários/
  end
end
