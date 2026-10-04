require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end

  setup do
    @account = accounts(:workspace_one)
    @admin = users(:lazaro_nixon)
    @member = User.create!(email: "member@example.com", password: "Secret1*3*5*", verified: true)
    @member.memberships.create!(account: @account, role: :member)
  end

  test "admin sets the workspace theme" do
    sign_in_as(@admin)

    patch account_url(@account), params: { account: { theme: "gruvbox" } }

    assert_redirected_to edit_account_path(@account)
    assert_equal "gruvbox", @account.reload.theme
  end

  test "sidebar palette pick redirects back with the theme set" do
    sign_in_as(@admin)

    patch account_url(@account), params: { account: { theme: "everforest" }, return_to: todos_path }

    assert_redirected_to todos_url
    assert_equal "everforest", @account.reload.theme
  end

  test "return_to off host falls back to settings" do
    sign_in_as(@admin)

    patch account_url(@account), params: { account: { theme: "everforest" }, return_to: "https://evil.example" }
    assert_redirected_to edit_account_path(@account)

    patch account_url(@account), params: { account: { theme: "gruvbox" }, return_to: "//evil.example/x" }
    assert_redirected_to edit_account_path(@account)
    assert_equal "gruvbox", @account.reload.theme
  end

  test "member cannot set the workspace theme" do
    sign_in_as(@member)

    patch account_url(@account), params: { account: { theme: "gruvbox" } }

    assert_redirected_to root_path
    assert_equal "stock", @account.reload.theme
  end

  test "initial HTML carries the theme attribute only when set" do
    sign_in_as(@admin)

    get dashboard_url
    assert_response :success
    assert_no_match(/data-theme=/, response.body)

    @account.update!(theme: "tokyo-night")
    get dashboard_url
    assert_response :success
    assert_match(/data-theme="tokyo-night"/, response.body)
  end
end
