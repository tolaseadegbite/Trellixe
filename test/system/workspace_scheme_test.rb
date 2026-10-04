require "application_system_test_case"

# Scheme preference is remembered per workspace: switching spaces
# restores each space's own light/dark without any clicks.
class WorkspaceSchemeTest < ApplicationSystemTestCase
  setup do
    @user = users(:lazaro_nixon)
    @first = accounts(:workspace_one)
    visit sign_in_url
    fill_in "Email", with: @user.email
    fill_in "Password", with: "Secret1*3*5*"
    click_on "Sign in"
    assert_text "Today's follow-ups", wait: 10
  end

  test "each workspace restores its own scheme on switch" do
    other = Account.create!(name: "Cell Two")
    @user.memberships.create!(account: other, role: :member)
    visit todos_url

    # Dark in the first workspace via the Theme popover.
    click_on "Theme"
    within("#dashboard-theme-switcher-popover") { click_on "Dark" }
    assert_selector "body[data-color-scheme='dark']"

    # Switch to the new workspace and pin it light via the Theme popover.
    click_on @first.name
    within("#workspace-switcher-popover") { click_on other.name }
    assert_text "Switched to #{other.name}"
    click_on "Theme"
    within("#dashboard-theme-switcher-popover") { click_on "Light" }
    assert_selector "body[data-color-scheme='light']"

    # Both spaces now restore their own scheme with zero clicks.
    click_on other.name
    within("#workspace-switcher-popover") { click_on @first.name }
    assert_text "Switched to #{@first.name}"
    assert_selector "body[data-color-scheme='dark']"
    click_on @first.name
    within("#workspace-switcher-popover") { click_on other.name }
    assert_text "Switched to #{other.name}"
    assert_selector "body[data-color-scheme='light']"
  end
end
