require "test_helper"

class NotificationsHelperTest < ActiveSupport::TestCase
  include NotificationsHelper

  setup do
    @user = users(:lazaro_nixon)
    @account = accounts(:workspace_one)
  end

  def note_for(type, params, recipient: @user)
    event = Noticed::Event.create!(type: type, params: params)
    Noticed::Notification.create!(event: event, recipient: recipient, account: @account)
  end

  test "role changed messages cover all four perspectives" do
    base = { account_name: "Cell One", role: "member", user_id: 2, user_name: "Adaeze Okafor",
             actor_id: 3, actor_name: "Juliane Barton" }

    assert_equal "Your role in Cell One was changed to Member by Juliane Barton.",
      notification_message(note_for("TeamNotifier::RoleChanged", base.merge(user_id: @user.id)))
    assert_equal "Your role in Cell One was changed to Member by you.",
      notification_message(note_for("TeamNotifier::RoleChanged",
        base.merge(user_id: @user.id, actor_id: @user.id, actor_name: @user.full_name)))
    assert_equal "Adaeze Okafor's role was changed to Member by you.",
      notification_message(note_for("TeamNotifier::RoleChanged", base.merge(actor_id: @user.id)))
    assert_equal "Adaeze Okafor's role was changed to Member by Juliane Barton.",
      notification_message(note_for("TeamNotifier::RoleChanged", base))
  end

  test "member lifecycle messages" do
    assert_equal "You have been removed from Cell One.",
      notification_message(note_for("TeamNotifier::MemberRemoved",
        { account_name: "Cell One", user_id: @user.id }))
    assert_equal "Adaeze Okafor was removed from the team by Juliane Barton.",
      notification_message(note_for("TeamNotifier::MemberRemoved",
        { account_name: "Cell One", user_id: 2, user_name: "Adaeze Okafor", actor_name: "Juliane Barton" }))
    assert_equal "Adaeze Okafor has left Cell One.",
      notification_message(note_for("TeamNotifier::MemberLeft",
        { account_name: "Cell One", user_name: "Adaeze Okafor" }))
    assert_equal "Adaeze Okafor has joined Cell One.",
      notification_message(note_for("TeamNotifier::MemberJoined",
        { account_name: "Cell One", user_name: "Adaeze Okafor" }))
    assert_equal "You have been invited to join Cell One.",
      notification_message(note_for("TeamNotifier::InvitationReceived", { account_name: "Cell One" }))
    assert_equal "decliner@example.com declined the invitation to Cell One.",
      notification_message(note_for("TeamNotifier::InvitationDeclined",
        { account_name: "Cell One", email: "decliner@example.com" }))
  end

  test "follow-up reminder prefers the live task, falls back when gone" do
    task = follow_up_tasks(:three)
    assert_equal "Follow up with #{task.contact.full_name}",
      notification_message(note_for("FollowUpTaskNotifier", { task: task }))

    doomed = follow_up_tasks(:four)
    ghost = note_for("FollowUpTaskNotifier", { task: doomed })
    doomed.destroy!
    assert_equal "Follow up reminder", notification_message(ghost)
  end
end
