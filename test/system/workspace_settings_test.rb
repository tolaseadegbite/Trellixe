require "application_system_test_case"

class WorkspaceSettingsTest < ApplicationSystemTestCase
  setup do
    @user = users(:lazaro_nixon)
    @account = accounts(:workspace_one)
    visit sign_in_url
    fill_in "Email", with: @user.email
    fill_in "Password", with: "Secret1*3*5*"
    click_on "Sign in"
    assert_text "Today's follow-ups", wait: 10
  end

  test "admin updates workspace reminder policy" do
    visit edit_account_path(@account)

    within("#reminder-settings") do
      # Flatpickr owns this field: set the time through its API (wire
      # format) so display, hidden value, and change listeners all sync.
      page.execute_script(
        "document.getElementById('account_reminder_clock')._flatpickr.setDate('07:30', true);"
      )
      fill_in "Follow up, days after event", with: "2"
      click_on "Save Changes"
    end

    assert_text "Workspace updated."
    @account.reload
    assert_equal "07:30", @account.reminder_clock
    assert_equal 2, @account.post_event_day_offset
  end
end
