class CreateTaggedEventSeries < ActiveRecord::Migration[8.0]
  def change
    create_table :tagged_event_series do |t|
      t.references :event_series, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :tagged_event_series, [ :event_series_id, :tag_id ], unique: true
  end
end
