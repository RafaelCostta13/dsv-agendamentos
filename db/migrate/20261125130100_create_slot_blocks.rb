class CreateSlotBlocks < ActiveRecord::Migration[8.1]
  def change
    create_table :slot_blocks do |t|
      t.date :blocked_date, null: false
      t.integer :dock_number, limit: 2, null: false
      t.integer :slot_number, limit: 2, null: false
      t.string :reason, limit: 250
      t.timestamps null: false
    end

    add_index :slot_blocks, [ :blocked_date, :dock_number, :slot_number ],
      unique: true, name: "slot_blocks_position_unique"
    add_check_constraint :slot_blocks, "dock_number BETWEEN 1 AND 8", name: "slot_blocks_dock_range"
    add_check_constraint :slot_blocks, "slot_number BETWEEN 1 AND 10", name: "slot_blocks_slot_range"
  end
end
