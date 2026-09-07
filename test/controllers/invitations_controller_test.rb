require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:lazaro_nixon)
    sign_in_as(@user)
    # invitations(:three) is attended with a pending task — the undo case.
    @invitation = invitations(:three)
    @task = follow_up_tasks(:three)
  end

  test "undoing attendance destroys the pending follow-up task" do
    assert_difference("FollowUpTask.count", -1) do
      patch bulk_update_invitations_url, params: { invitation_ids: [ @invitation.id ], status: "invited" }
    end

    assert_redirected_to events_path
    assert @invitation.reload.invited?
    assert_not FollowUpTask.exists?(@task.id)
  end

  test "undoing attendance keeps completed work and its logs" do
    log = @task.interaction_logs.create!(contact: @invitation.contact, user: @user, note: "Called.")
    @task.update!(completed_at: Time.current)

    assert_no_difference("FollowUpTask.count") do
      patch bulk_update_invitations_url, params: { invitation_ids: [ @invitation.id ], status: "invited" }
    end

    assert @invitation.reload.invited?
    assert FollowUpTask.exists?(@task.id)
    assert InteractionLog.exists?(log.id)
  end

  test "re-checking after undo queues a fresh task" do
    patch bulk_update_invitations_url, params: { invitation_ids: [ @invitation.id ], status: "invited" }
    assert_not FollowUpTask.exists?(@task.id)

    assert_difference("FollowUpTask.count", 1) do
      patch bulk_update_invitations_url, params: { invitation_ids: [ @invitation.id ], status: "attended" }
    end

    assert @invitation.reload.attended?
  end
end
