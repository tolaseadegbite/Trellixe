require "test_helper"

class TeamInvitationAcceptancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:lazaro_nixon)
    sign_in_as(@user)
    @invitation = TeamInvitation.create!(
      account: accounts(:workspace_one), email: "decliner@example.com"
    )
  end

  test "should decline invitation" do
    assert_difference("TeamInvitation.count", -1) do
      delete team_invitation_acceptance_url(token: @invitation.token)
    end

    assert_redirected_to root_path
  end

  test "decline notifies all admins" do
    other_admin = User.new(email: "coadmin@example.com", password: "Secret1*3*5*")
    other_admin.save!(validate: false)
    Membership.create!(user: other_admin, account: accounts(:workspace_one), role: "admin")

    perform_enqueued_jobs do
      delete team_invitation_acceptance_url(token: @invitation.token)
    end

    notes = Noticed::Notification.where(type: "TeamNotifier::InvitationDeclined::Notification")
    assert_equal 2, notes.count
    assert_equal [ @user.id, other_admin.id ].sort, notes.map(&:recipient_id).sort
    assert notes.all? { |n| n.account_id == accounts(:workspace_one).id }
  end

  test "should reject invalid decline token" do
    assert_no_difference("TeamInvitation.count") do
      delete team_invitation_acceptance_url(token: "bogus-token")
    end

    assert_redirected_to root_path
  end
end
