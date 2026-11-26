class CreateAuthenticatedSessions < ActiveRecord::Migration[8.1]
  def up
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :restrict }
      t.string :token_digest, limit: 64, null: false
      t.datetime :last_seen_at, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.string :user_agent, limit: 500
      t.timestamps
    end
    add_index :sessions, :token_digest, unique: true
    add_index :sessions, :expires_at
    add_index :sessions, :revoked_at
    add_check_constraint :sessions, "char_length(token_digest) = 64", name: "sessions_token_digest_length"
    add_check_constraint :sessions, "last_seen_at >= created_at AND expires_at > created_at", name: "sessions_valid_times"

    create_table :login_attempts do |t|
      t.string :key_kind, limit: 10, null: false
      t.string :key_digest, limit: 64, null: false
      t.datetime :occurred_at, null: false
    end
    add_index :login_attempts, [ :key_kind, :key_digest, :occurred_at ], name: "login_attempts_lookup"
    add_index :login_attempts, :occurred_at
    add_check_constraint :login_attempts, "key_kind IN ('email', 'ip')", name: "login_attempts_kind_allowed"
    add_check_constraint :login_attempts, "char_length(key_digest) = 64", name: "login_attempts_digest_length"

    change_table :audit_events do |t|
      t.references :actor_user, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :actor_name, limit: 100
      t.string :actor_role, limit: 30
      t.string :origin, limit: 30
    end
    add_index :audit_events, :origin
    add_check_constraint :audit_events,
      "origin IS NULL OR origin IN ('public_form', 'authenticated_user', 'system', 'bootstrap', 'unknown')",
      name: "audit_events_origin_allowed"
    add_check_constraint :audit_events,
      "actor_role IS NULL OR actor_role IN ('admin', 'operator', 'viewer')",
      name: "audit_events_actor_role_allowed"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Authentication sessions and audit attribution must be preserved"
  end
end
