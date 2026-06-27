class CreateEventSeries < ActiveRecord::Migration[8.0]
  def change
    create_table :event_series do |t|
      t.references :owner, polymorphic: true, null: false
      t.string :name, null: false
      t.integer :duration_in_minutes, null: false
      t.datetime :starts_at, null: false
      t.jsonb :recurrence_rule, null: false, default: {}
      t.date :ends_on
      t.boolean :cancelled_series, default: false

      t.timestamps
    end
  end
end
