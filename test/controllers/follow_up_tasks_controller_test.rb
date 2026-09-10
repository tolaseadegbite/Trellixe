require "test_helper"

class FollowUpTasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:lazaro_nixon)
    sign_in_as(@user)
    @task = follow_up_tasks(:three)
    @account = accounts(:workspace_one)
  end

  test "bulk done marks related notifications read" do
    FollowUpTaskNotifier.with(
      task: @task, account_id: @account.id, user_name: @user.full_name
    ).deliver(@user)
    note = Noticed::Notification.last
    assert_predicate note, :unread?

    patch bulk_update_follow_up_tasks_url,
      params: { task_ids: [ @task.id ], commit: "Done" }, as: :turbo_stream

    assert_response :success
    assert_predicate note.reload, :read?
  end

  test "bulk snooze keeps notifications unread" do
    FollowUpTaskNotifier.with(
      task: @task, account_id: @account.id, user_name: @user.full_name
    ).deliver(@user)
    note = Noticed::Notification.last

    patch bulk_update_follow_up_tasks_url,
      params: { task_ids: [ @task.id ], commit: "Snooze 24h" }, as: :turbo_stream

    assert_response :success
    assert_predicate note.reload, :unread?
  end
end
