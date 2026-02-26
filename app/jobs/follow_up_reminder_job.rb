class FollowUpReminderJob < ApplicationJob
  queue_as :default

  def perform(follow_up_task)
    # 1. Stop if done
    return if follow_up_task.completed_at? || follow_up_task.interaction_logs.exists?

    # 2. TIME GUARD: Only notify if the current time is greater than or equal to the due_at
    # If the user snoozed it, Time.current will be LESS than due_at, so we skip the notification.
    if Time.current >= follow_up_task.due_at
      FollowUpTaskNotifier.with(task: follow_up_task).deliver(follow_up_task.user)
    end

    # 3. Reschedule the next check
    # The loop continues, but it will be "silent" until the snooze time expires.
    self.class.set(wait: 1.minute).perform_later(follow_up_task)
  end
end
