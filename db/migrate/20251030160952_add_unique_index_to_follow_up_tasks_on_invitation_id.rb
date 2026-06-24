class AddUniqueIndexToFollowUpTasksOnInvitationId < ActiveRecord::Migration[8.0]
  def change
    # 1. Remove the existing non-unique index
    remove_index :follow_up_tasks, :invitation_id

    # 2. Add a new unique index to enforce that each invitation
    #    can only ever have one follow-up task.
    add_index :follow_up_tasks, :invitation_id, unique: true
  end
end
