class AddEventSeriesToEvents < ActiveRecord::Migration[8.0]
  def change
    add_reference :events, :event_series, null: true, foreign_key: true
  end
end
