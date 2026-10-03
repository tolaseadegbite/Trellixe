require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:lazaro_nixon)
    @account = accounts(:workspace_one)
    sign_in_as(@user)
  end

  test "opening the index marks in-scope unread notifications read" do
    deliver_account_notification(@account)
    deliver_global_notification
    foreign = deliver_account_notification(accounts(:workspace_two))

    assert_difference -> { @user.notifications.unread.count }, -2 do
      get notifications_url
    end

    assert_response :success
    assert_predicate foreign.reload, :unread?
    # Rows render read on first paint — no unread dots or highlights.
    assert_select "#notifications-list .bg-algae-600", count: 0
    assert_select "#notifications-list .bg-algae-50\\/60", count: 0
  end

  test "mark_all_as_read still clears from the popover path" do
    deliver_account_notification(@account)

    post mark_all_as_read_notifications_url

    assert_redirected_to notifications_path
    assert_empty @user.notifications.unread
  end

  private

  def deliver_account_notification(account)
    TeamNotifier::RoleChanged.with(
      account_id: account.id,
      account_name: account.name,
      user_id: @user.id,
      user_name: @user.full_name,
      actor_id: @user.id,
      actor_name: @user.full_name,
      role: "member"
    ).deliver(@user)
    Noticed::Notification.last
  end

  def deliver_global_notification
    TeamNotifier::InvitationReceived.with(
      account_name: @account.name,
      token: "test-token-123"
    ).deliver(@user)
    Noticed::Notification.last
  end
end
