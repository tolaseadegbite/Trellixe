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
    # Generous wait: cold headless browsers stall on first paint.
    assert_text "Today's follow-ups", wait: 10
  end

  test "members page renders active list and pending tab" do
    visit members_url

    assert_text "Team members"
    assert_text @user.email

    click_on "Pending invites"
    assert_text "Pending invites"
  end

  test "settings submenu has no notifications link" do
    visit members_url

    assert_no_selector "details a[href='#{notifications_path}']"
  end

  test "notification badge roots carry stream target ids" do
    visit members_url

    assert_selector "#sidebar-notification-badge", visible: :all
    assert_selector "#header-notification-badge", visible: :all
    assert_no_selector "#sidebar-m-notification-badge", visible: :all
  end

  test "notification row links disable prefetch" do
    event = Noticed::Event.create!(type: "TeamNotifier::MemberJoined",
      params: { account_id: accounts(:workspace_one).id,
                account_name: "Cell One", user_name: "Hover Probe" })
    note = Noticed::Notification.create!(event: event, recipient: @user,
      account: accounts(:workspace_one))

    visit members_url

    assert_selector "#sidebar-notifications-list a[data-turbo-prefetch='false'][href='#{notification_path(note)}']",
      visible: :all
  end
end
