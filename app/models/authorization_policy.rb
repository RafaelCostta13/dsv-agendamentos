class AuthorizationPolicy
  PERMISSIONS = {
    dashboard: %w[admin operator viewer], bookings_read: %w[admin operator viewer], receipts: %w[admin operator viewer],
    blocks_read: %w[admin operator viewer], operations: %w[admin operator], blocks_write: %w[admin operator],
    audit_read: %w[admin operator viewer], users_manage: %w[admin], profile: %w[admin operator viewer], export: %w[admin operator viewer]
  }.freeze

  ROUTES = {
    "admin/dashboard" => { "index" => :dashboard, "refresh" => :dashboard },
    "admin/bookings" => { "index" => :bookings_read, "show" => :bookings_read, "receipt" => :receipts, "export" => :export,
      "confirm_checkin" => :operations, "confirm_release" => :operations, "checkin" => :operations, "release" => :operations },
    "admin/booking_changes" => %w[edit cancellation cancel reschedule].index_with { :operations },
    "admin/slot_blocks" => { "index" => :blocks_read, "create" => :blocks_write, "unblocking" => :blocks_write,
      "review_unblock" => :blocks_write, "destroy" => :blocks_write, "bulk_unblock" => :blocks_write },
    "admin/audit_events" => %w[index show].index_with { :audit_read },
    "admin/users" => %w[index new create show edit update activation deactivation activate deactivate password_reset reset_password].index_with { :users_manage },
    "admin/profiles" => { "show" => :profile }
  }.freeze

  def self.permission_for(controller_path, action_name)
    mapping = ROUTES.fetch(controller_path, {})
    mapping[action_name] || mapping.default
  end

  def self.allowed?(user, permission)
    user&.active? && permission && PERMISSIONS.fetch(permission, []).include?(user.role)
  end
end
