class FollowUpReminderJob < ApplicationJob
  queue_as :default

  def perform(follow_up_task)
    return if follow_up_task.interaction_logs.exists?

    FollowUpTaskNotifier.with(task: follow_up_task).deliver(follow_up_task.user)

    self.class.set(wait: 1.minute).perform_later(follow_up_task)
  end
end
