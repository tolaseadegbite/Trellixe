class FollowUpReminderJob < ApplicationJob
  def perform(follow_up_task)
    return if follow_up_task.completed_at? || follow_up_task.interaction_logs.exists?

    if Time.current >= follow_up_task.due_at
      FollowUpTaskNotifier.with(
        task: follow_up_task,
        account_id: follow_up_task.invitation.event.owner_id,
        user_name: follow_up_task.contact.full_name
      ).deliver(follow_up_task.user)
      return
    end

    self.class.set(wait: 1.minute).perform_later(follow_up_task)
  end
end
