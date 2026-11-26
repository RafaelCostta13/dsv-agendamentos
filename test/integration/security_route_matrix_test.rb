require "test_helper"

class SecurityRouteMatrixTest < ActionDispatch::IntegrationTest
  test "all administrative routes require valid authentication and explicit permission" do
    routes.each do |route, path|
      permission = AuthorizationPolicy.permission_for(route.defaults[:controller], route.defaults[:action])
      assert permission, "unmapped route #{path}"
      public_send(route.verb.downcase, path)
      assert_response(path.include?("/dashboard/refresh") ? :unauthorized : :redirect)
    end
  end

  %w[admin operator viewer].each do |role|
    test "#{role} denied routes do not mutate records" do
      user = sign_in_as(role: role)
      routes.each do |route, path|
        permission = AuthorizationPolicy.permission_for(route.defaults[:controller], route.defaults[:action])
        next if AuthorizationPolicy.allowed?(user, permission)
        assert_no_difference [ "Booking.count", "SlotBlock.count", "User.count", "AuditEvent.count" ] do
          public_send(route.verb.downcase, path)
          assert_response :forbidden
        end
      end
    end
  end

  %w[revoked expired inactive mandatory].each do |state|
    test "#{state} authentication cannot access any operational route" do
      user = sign_in_as
      credential = Session.order(:id).last
      case state
      when "revoked" then credential.revoke!
      when "expired" then credential.update!(last_seen_at: 31.minutes.ago)
      when "inactive" then user.update!(active: false, deactivated_at: Time.current)
      when "mandatory" then user.update!(must_change_password: true)
      end
      routes.each do |route, path|
        public_send(route.verb.downcase, path)
        if path.include?("/dashboard/refresh")
          assert_response :unauthorized
        else
          assert_response :redirect
          assert_redirected_to(state == "mandatory" ? edit_password_path : login_path)
        end
      end
    end
  end

  private

  def routes
    Rails.application.routes.routes.filter_map do |route|
      next unless route.defaults[:controller].to_s.start_with?("admin/")
      next unless %w[GET POST PATCH PUT DELETE].include?(route.verb)
      path = route.path.spec.to_s.sub("(.:format)", "").gsub(":id", "999999999999")
      [ route, path ]
    end
  end
end
