class AllowStandaloneInteractionLogs < ActiveRecord::Migration[8.0]
  def change
    change_column_null :interaction_logs, :follow_up_task_id, true
  end
end
