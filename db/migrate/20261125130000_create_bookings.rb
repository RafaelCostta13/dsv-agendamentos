class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.string :protocol, limit: 50, null: false
      t.uuid :request_id, null: false
      t.date :booking_date, null: false
      t.integer :dock_number, limit: 2, null: false
      t.integer :slot_number, limit: 2, null: false
      t.string :operation, limit: 20, null: false
      t.string :status, limit: 30, null: false, default: "agendado"
      t.string :contact_name, limit: 80, null: false
      t.string :company, limit: 100, null: false
      t.string :invoice, limit: 44, null: false
      t.string :plate, limit: 7, null: false
      t.string :vehicle_model, limit: 80, null: false
      t.datetime :checkin_at
      t.datetime :released_at
      t.text :release_remark
      t.text :change_reason
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end

    add_index :bookings, :protocol, unique: true
    add_index :bookings, :request_id, unique: true
    add_index :bookings, :booking_date
    add_index :bookings, [ :booking_date, :dock_number, :slot_number ],
      unique: true, name: "bookings_active_slot_unique",
      where: "status IN ('agendado', 'em_operacao', 'liberado')"
    add_index :bookings, :dock_number, unique: true,
      name: "bookings_dock_occupation_unique", where: "status = 'em_operacao'"

    add_check_constraint :bookings, "dock_number BETWEEN 1 AND 8", name: "bookings_dock_range"
    add_check_constraint :bookings, "slot_number BETWEEN 1 AND 10", name: "bookings_slot_range"
    add_check_constraint :bookings, "operation IN ('entrega', 'coleta')", name: "bookings_operation_allowed"
    add_check_constraint :bookings,
      "status IN ('agendado', 'em_operacao', 'liberado', 'cancelado', 'reagendamento')",
      name: "bookings_status_allowed"
    add_check_constraint :bookings, "invoice ~ '^[0-9]{1,44}$'", name: "bookings_invoice_digits"
    add_check_constraint :bookings, "lock_version >= 0", name: "bookings_lock_version_nonnegative"
    add_check_constraint :bookings,
      "released_at IS NULL OR (checkin_at IS NOT NULL AND released_at >= checkin_at)",
      name: "bookings_release_chronology"
    add_check_constraint :bookings,
      "status <> 'em_operacao' OR checkin_at IS NOT NULL", name: "bookings_operation_checkin"
    add_check_constraint :bookings, <<~SQL.squish, name: "bookings_released_details"
      status <> 'liberado' OR (
        checkin_at IS NOT NULL AND released_at IS NOT NULL AND release_remark IS NOT NULL
        AND char_length(regexp_replace(release_remark, '^[[:space:]]+|[[:space:]]+$', '', 'g')) BETWEEN 3 AND 500
      )
    SQL
  end
end
