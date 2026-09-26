class FollowUpReminderJob < ApplicationJob
  # Undone check-ins destroy their pending tasks; the already-scheduled
  # reminder for a gone task dies quietly instead of retrying forever.
  discard_on ActiveJob::DeserializationError

  # due_at is a token for the due time this run was scheduled for. When a
  # task is snoozed its due_at moves and a fresh job is enqueued for the new
  # time; the stale run sees the mismatch and dies quietly instead of
  # polling every minute until the new due time. Compared in epoch seconds:
  # DB round-trips truncate sub-second precision, so strict == would misfire.
  # Nil keeps legacy (pre-token) enqueued jobs working as before.
  def perform(follow_up_task, due_at = nil)
    return if due_at && follow_up_task.due_at.to_i != due_at.to_i
    return if follow_up_task.completed_at? || follow_up_task.interaction_logs.exists?

    if Time.current >= follow_up_task.due_at
      FollowUpTaskNotifier.with(
        task: follow_up_task,
        account_id: follow_up_task.invitation.event.owner_id,
        user_name: follow_up_task.contact.full_name
      ).deliver(follow_up_task.user)
      return
    end

    self.class.set(wait: 1.minute).perform_later(follow_up_task, due_at)
  end
end
