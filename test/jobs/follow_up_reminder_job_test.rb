require "test_helper"

class FollowUpReminderJobTest < ActiveJob::TestCase
  setup do
    @task = follow_up_tasks(:three)
  end

  test "delivers when token matches the task due time" do
    @task.update!(due_at: 1.minute.ago)

    assert_difference -> { Noticed::Notification.count }, 1 do
      FollowUpReminderJob.perform_now(@task, @task.due_at)
    end
  end

  test "discards stale run when due_at moved on by a snooze" do
    @task.update!(due_at: 24.hours.from_now)

    assert_no_enqueued_jobs do
      assert_no_difference -> { Noticed::Notification.count } do
        FollowUpReminderJob.perform_now(@task, 1.hour.ago)
      end
    end
  end

  test "legacy run without a token still delivers" do
    @task.update!(due_at: 1.minute.ago)

    assert_difference -> { Noticed::Notification.count }, 1 do
      FollowUpReminderJob.perform_now(@task)
    end
  end
end
