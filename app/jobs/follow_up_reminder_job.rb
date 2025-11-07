class FollowUpReminderJob < ApplicationJob
  queue_as :default

  def perform(follow_up_task)
    # 1. CHECK THE STOPPING CONDITION:
    # If the user has already logged an interaction for this task, we stop.
    # The `return` statement immediately exits the job.
    return if follow_up_task.interaction_logs.exists?

    # 2. SEND THE NOTIFICATION:
    # If no interaction log exists, we trigger the notifier to send the reminder.
    # The Noticed gem will handle creating and running the delivery jobs.
    FollowUpTaskNotifier.with(task: follow_up_task).deliver(follow_up_task.user)

    # 3. RESCHEDULE THE NEXT REMINDER:
    # Enqueue a new instance of this same job to run again in the future.
    # For testing, we'll wait 1 minute.
    self.class.set(wait: 24.hours).perform_later(follow_up_task)
  end
end