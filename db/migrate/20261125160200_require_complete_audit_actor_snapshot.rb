class RequireCompleteAuditActorSnapshot < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :audit_events,
      "(actor_user_id IS NULL AND actor_name IS NULL AND actor_role IS NULL) OR " \
      "(actor_user_id IS NOT NULL AND actor_name IS NOT NULL AND actor_role IS NOT NULL)",
      name: "audit_events_actor_snapshot_complete"
  end
end
