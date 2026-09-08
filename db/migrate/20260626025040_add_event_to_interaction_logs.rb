class AddEventToInteractionLogs < ActiveRecord::Migration[8.0]
  def change
    add_reference :interaction_logs, :event, null: true, foreign_key: true
  end
end
