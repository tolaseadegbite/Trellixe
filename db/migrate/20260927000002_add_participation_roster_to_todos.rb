class AddParticipationRosterToTodos < ActiveRecord::Migration[8.0]
  def change
    create_table :todo_participations do |t|
      t.references :todo, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :todo_participations, %i[ todo_id user_id ], unique: true

    remove_column :todo_contacts, :completed_at, :datetime

    # Nil assignee = the whole team.
    change_column_null :todos, :user_id, true
  end
end
