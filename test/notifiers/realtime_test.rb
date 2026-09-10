require "test_helper"

# Guards the realtime notification path end to end at the contract level:
# the browser must have a cable endpoint to subscribe to, and notifiers
# must broadcast onto the exact streams the layout subscribes to.
class RealtimeTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  setup do
    @user = users(:lazaro_nixon)
    sign_in_as(@user)
  end

  test "action cable endpoint is mounted" do
    paths = Rails.application.routes.routes.map { |r| r.path.spec.to_s }

    assert_includes paths, "/cable"
  end

  test "global notifications broadcast onto the recipient global stream" do
    perform_enqueued_jobs do
      TeamNotifier::InvitationReceived.with(
        account_name: accounts(:workspace_one).name,
        token: "test-token-123"
      ).deliver(@user)
    end

    messages = broadcasts("notifications_#{@user.id}_global")
    assert messages.any? { |m| m.include?("sidebar-notifications-list") },
      "expected a notification list prepend on the global stream"
  end

  test "account notifications broadcast onto the account stream" do
    perform_enqueued_jobs do
      TeamNotifier::RoleChanged.with(
        account_id: accounts(:workspace_one).id,
        account_name: accounts(:workspace_one).name,
        user_id: @user.id,
        user_name: @user.full_name,
        actor_id: @user.id,
        actor_name: @user.full_name,
        role: "member"
      ).deliver(@user)
    end

    messages = broadcasts("notifications_#{@user.id}_account_#{accounts(:workspace_one).id}")
    assert messages.any? { |m| m.include?("sidebar-notifications-list") },
      "expected a notification list prepend on the account stream"
  end
end
