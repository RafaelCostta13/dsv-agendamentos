class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events do |t|
      t.string :entity_type, limit: 50, null: false
      t.bigint :entity_id, null: false
      t.string :action, limit: 50, null: false
      t.jsonb :previous_values
      t.jsonb :new_values
      t.text :reason
      t.datetime :created_at, null: false
    end

    add_index :audit_events, [ :entity_type, :entity_id ]
    add_check_constraint :audit_events, "entity_type IN ('Booking', 'SlotBlock')",
      name: "audit_events_entity_type_allowed"
  end
end
