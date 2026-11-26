class RelaxSessionClockConstraint < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :sessions, name: "sessions_valid_times"
    add_check_constraint :sessions, "expires_at > created_at", name: "sessions_valid_times"
  end
end
