require "application_system_test_case"

# The sidebar menu renders twice per page (desktop aside + mobile drawer
# dialog). Popover ids must be unique per instance, or native
# popovertarget resolves to the hidden desktop copy and mobile taps
# visibly do nothing.
class MobileSidebarTest < ApplicationSystemTestCase
  setup do
    @user = users(:lazaro_nixon)
    @account = accounts(:workspace_one)
    visit sign_in_url
    fill_in "Email", with: @user.email
    fill_in "Password", with: "Secret1*3*5*"
    click_on "Sign in"
    assert_text "Today's follow-ups", wait: 10
    page.driver.browser.manage.window.resize_to(390, 844)
  end

  teardown do
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end

  test "workspace switcher opens inside the mobile drawer" do
    find("button[aria-label='Open menu']").click
    assert_selector "dialog[open]"

    within("dialog[open]") { click_on @account.name }

    assert popover_open?("#workspace-switcher-popover-mobile"),
      "expected the mobile workspace popover to open"
    within("#workspace-switcher-popover-mobile") do
      assert_text @account.name
    end
  end

  test "switching workspace from the mobile drawer" do
    other = Account.create!(name: "Cell Two")
    @user.memberships.create!(account: other, role: :member)
    visit todos_url

    find("button[aria-label='Open menu']").click
    within("dialog[open]") { click_on @account.name }
    within("#workspace-switcher-popover-mobile") { click_on other.name }

    assert_text "Switched to #{other.name}"
  end

  test "popover ids are unique per shell instance" do
    visit todos_url

    assert_equal 1, all("#workspace-switcher-popover", visible: :all).size
    assert_equal 1, all("#workspace-switcher-popover-mobile", visible: :all).size
    assert_equal 1, all("#dashboard-theme-switcher-popover", visible: :all).size
    assert_equal 1, all("#dashboard-theme-switcher-popover-mobile", visible: :all).size
  end

  private

  def popover_open?(selector)
    page.evaluate_script("document.querySelector('#{selector}')?.matches(':popover-open')")
  end
end
