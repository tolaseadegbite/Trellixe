require "application_system_test_case"

class NotificationsTest < ApplicationSystemTestCase
  setup do
    @user = users(:lazaro_nixon)
    @account = accounts(:workspace_one)
    TeamNotifier::RoleChanged.with(
      account_id: @account.id,
      account_name: @account.name,
      user_id: @user.id,
      user_name: @user.full_name,
      actor_id: @user.id,
      actor_name: @user.full_name,
      role: "member"
    ).deliver(@user)

    visit sign_in_url
    fill_in "Email", with: @user.email
    fill_in "Password", with: "Secret1*3*5*"
    click_on "Sign in"
    assert_text "Today's follow-ups", wait: 10
  end

  test "opening the notifications page clears the unread badge with no clicks" do
    # Mobile viewport: the header bell (with its badge) is the entry point;
    # the desktop sidebar popover is hidden here.
    page.driver.browser.manage.window.resize_to(390, 844)

    assert_selector "#header-notification-badge .bg-red-500"

    find("a[aria-label='Notifications']").click

    assert_text "All notifications"
    assert_no_selector "#header-notification-badge .bg-red-500"
    assert_no_selector "#notifications-list .bg-algae-600"
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end
end
