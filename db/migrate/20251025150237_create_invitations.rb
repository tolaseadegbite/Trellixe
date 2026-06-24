class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :invitations, [ :contact_id, :event_id ], unique: true
  end
end
