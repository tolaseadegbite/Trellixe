class CreateTodos < ActiveRecord::Migration[8.0]
  def change
    create_table :todos do |t|
      t.references :account, null: false, foreign_key: true
      t.string :title, null: false
      t.references :user, null: false, foreign_key: true
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.datetime :due_at
      t.datetime :completed_at
      t.string :visibility, null: false, default: "shared"
      t.integer :target_count
      t.integer :progress_count, null: false, default: 0

      t.timestamps
    end

    create_table :todo_contacts do |t|
      t.references :todo, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.datetime :completed_at

      t.timestamps
    end
    add_index :todo_contacts, %i[ todo_id contact_id ], unique: true
  end
end
