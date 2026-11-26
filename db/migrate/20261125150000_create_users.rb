class CreateUsers < ActiveRecord::Migration[8.1]
  def up
    create_table :users do |t|
      t.string :name, limit: 100, null: false
      t.string :email, limit: 254, null: false
      t.string :password_digest, null: false
      t.string :role, limit: 30, null: false
      t.boolean :active, null: false, default: true
      t.boolean :must_change_password, null: false, default: true
      t.datetime :password_changed_at
      t.datetime :deactivated_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :users, "lower(email)", unique: true, name: "users_email_unique"
    add_check_constraint :users, "role IN ('admin', 'operator', 'viewer')", name: "users_role_allowed"
    add_check_constraint :users, "(active AND deactivated_at IS NULL) OR (NOT active AND deactivated_at IS NOT NULL)", name: "users_active_consistent"
    add_check_constraint :users, "lock_version >= 0", name: "users_lock_version_nonnegative"
    add_check_constraint :users, "char_length(btrim(name)) >= 2 AND char_length(btrim(email)) > 0", name: "users_identity_present"
    remove_check_constraint :audit_events, name: "audit_events_entity_type_allowed"
    add_check_constraint :audit_events, "entity_type IN ('Booking', 'SlotBlock', 'User')", name: "audit_events_entity_type_allowed"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Users and their audit history must be preserved"
  end
end
