class AddNotifiedAtToFollowUpTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :follow_up_tasks, :notified_at, :datetime
    add_index :follow_up_tasks, :notified_at, where: "notified_at IS NULL"
  end
end
