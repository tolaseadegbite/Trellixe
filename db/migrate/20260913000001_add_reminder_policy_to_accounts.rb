class AddReminderPolicyToAccounts < ActiveRecord::Migration[8.0]
  def change
    change_table :accounts, bulk: true do |t|
      t.string :reminder_clock, default: "09:00", null: false
      t.boolean :pre_event_enabled, default: true, null: false
      t.integer :pre_event_day_offset, default: 1, null: false
      t.integer :pre_event_buffer_minutes, default: 120, null: false
      t.integer :post_event_day_offset, default: 1, null: false
    end

    create_table :pre_event_digests do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :fire_at, null: false
      t.datetime :sent_at
      t.timestamps
    end
    add_index :pre_event_digests, [ :event_id, :user_id ], unique: true,
      where: "sent_at IS NULL", name: "index_pre_event_digests_unsent"
  end
end
