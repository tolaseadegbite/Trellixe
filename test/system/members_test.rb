require "application_system_test_case"

class MembersTest < ApplicationSystemTestCase
  setup do
    @user = users(:lazaro_nixon)
    visit sign_in_url
    fill_in "Email", with: @user.email
    fill_in "Password", with: "Secret1*3*5*"
    click_on "Sign in"
    # Wait for the authenticated render (server HTML, no JS dependency)
    # before navigating — POST+redirect otherwise races the next visit.
    assert_text "Today's follow-ups"
  end

  test "members page renders active list and pending tab" do
    visit members_url

    assert_text "Team members"
    assert_text @user.email

    click_on "Pending invites"
    assert_text "Pending invites"
  end
end
