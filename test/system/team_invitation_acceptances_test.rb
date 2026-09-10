require "application_system_test_case"

class TeamInvitationAcceptancesTest < ApplicationSystemTestCase
  test "declining via confirm dialog destroys the invitation" do
    invitation = TeamInvitation.create!(
      account: Account.create!(name: "Dialog Cell"),
      email: "decliner-dialog@example.com"
    )

    visit team_invitation_acceptance_path(token: invitation.token)
    click_on "Decline invitation", match: :first
    within("dialog[open]") { click_on "Decline invitation" }

    assert_text "Invitation declined."
    assert_not TeamInvitation.exists?(invitation.id)
  end
end
