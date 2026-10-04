require "application_system_test_case"

# Workspace themes apply server-rendered and re-skin dark mode with no
# reload flash. Mirrors the stock-parity proof: exact computed backgrounds.
class ThemeTest < ApplicationSystemTestCase
  THEME_BODY_BG = {
    "Osaka Jade" => "rgb(9, 15, 13)",
    "Solitude" => "rgb(8, 10, 11)",
    "Giants" => "rgb(20, 18, 16)",
    "Retro 82" => "rgb(2, 12, 23)",
    "Miasma" => "rgb(18, 18, 18)",
    "Tokyo Night" => "rgb(14, 14, 20)",
    "Matte Black" => "rgb(9, 9, 9)",
    "Gruvbox" => "rgb(22, 22, 22)",
    "Everforest" => "rgb(24, 29, 32)"
  }.freeze

  setup do
    @user = users(:lazaro_nixon)
    @account = accounts(:workspace_one)
  end

  test "stock workspace renders no theme attribute" do
    sign_in_with(@user.email)
    visit todos_url

    assert_no_selector "body[data-theme]", visible: :all
  end

  test "admin picks a theme from the sidebar popover" do
    sign_in_with(@user.email)
    visit todos_url
    click_on "Theme"
    click_on "Gruvbox"

    assert_selector "body[data-theme='gruvbox']", visible: :all
    assert_equal "rgb(22, 22, 22)",
      evaluate_script("getComputedStyle(document.body).backgroundColor")
    # Stays where you clicked — no teleport to settings.
    assert_equal todos_path, current_path
  end

  test "settings previews the palette before saving" do
    sign_in_with(@user.email)
    visit edit_account_path(@account)

    within("#appearance-settings") { choose "Tokyo Night" }

    assert_selector "body[data-theme='tokyo-night']", visible: :all
    execute_script("document.body.dataset.colorScheme = 'dark'")
    assert_equal "rgb(14, 14, 20)",
      evaluate_script("getComputedStyle(document.body).backgroundColor")
    assert_equal "stock", @account.reload.theme
  end

  test "settings save flips to dark so the saved theme shows" do
    sign_in_with(@user.email)
    visit edit_account_path(@account)

    within("#appearance-settings") do
      choose "Everforest"
      click_on "Save Changes"
    end

    assert_text "Workspace updated"
    assert_selector "body[data-theme='everforest'][data-color-scheme='dark']", visible: :all
  end

  test "sidebar popover pick applies first click from the settings page" do
    sign_in_with(@user.email)
    visit edit_account_path(@account)
    click_on "Theme"
    click_on "Everforest"

    assert_selector "body[data-theme='everforest']", visible: :all
    assert_equal "everforest", @account.reload.theme
    assert_equal edit_account_path(@account), current_path
    execute_script("document.body.dataset.colorScheme = 'dark'")
    assert_equal "rgb(24, 29, 32)",
      evaluate_script("getComputedStyle(document.body).backgroundColor")
  end

  test "member sees no workspace palettes in the popover" do
    member = User.create!(email: "plain@example.com", password: "Secret1*3*5*", verified: true)
    member.memberships.create!(account: @account, role: :member)
    sign_in_with(member.email)

    visit todos_url
    click_on "Theme"

    assert_no_selector "a", text: "Gruvbox", visible: :all
    assert_no_selector "a", text: "Tokyo Night", visible: :all
  end

  test "admin picks a theme and dark mode re-skins" do
    sign_in_with(@user.email)
    THEME_BODY_BG.each do |label, expected_bg|
      visit edit_account_path(@account)
      within("#appearance-settings") do
        choose label
        click_on "Save Changes"
      end
      assert_text "Workspace updated"

      visit todos_url
      assert_selector "body[data-theme]", visible: :all
      execute_script("document.body.dataset.colorScheme = 'dark'")
      assert_equal expected_bg, evaluate_script("getComputedStyle(document.body).backgroundColor")
    end
  end

  private

  def sign_in_with(email)
    visit sign_in_url
    fill_in "Email", with: email
    fill_in "Password", with: "Secret1*3*5*"
    click_on "Sign in"
    assert_text "Today's follow-ups", wait: 10
  end
end
