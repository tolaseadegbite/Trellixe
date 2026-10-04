require "application_system_test_case"

# Stock-parity proof for surface tokenization: the token-backed utilities
# must resolve to the exact stock hexes in both modes, with no theme set.
# Any future palette work asserts against these same values for stock.
class ThemeParityTest < ApplicationSystemTestCase
  setup do
    @user = users(:lazaro_nixon)
    visit sign_in_url
    fill_in "Email", with: @user.email
    fill_in "Password", with: "Secret1*3*5*"
    click_on "Sign in"
    assert_text "Today's follow-ups", wait: 10
  end

  test "stock dark surfaces resolve to stock hexes" do
    visit todos_url
    execute_script("document.body.dataset.colorScheme = 'dark'")

    assert_equal "rgb(12, 18, 16)", computed_style("body", "backgroundColor")
    assert_equal "rgb(19, 27, 23)", computed_style("#todos-list", "backgroundColor")
    assert_equal "rgb(231, 236, 233)", computed_style("#todos-list", "color")
  end

  test "stock light surfaces resolve to stock hexes" do
    visit todos_url
    execute_script("document.body.dataset.colorScheme = 'light'")

    assert_equal "rgb(241, 244, 242)", computed_style("body", "backgroundColor")
    assert_equal "rgb(255, 255, 255)", computed_style("#todos-list", "backgroundColor")
    assert_equal "rgb(28, 36, 32)", computed_style("#todos-list", "color")
  end

  private

  def computed_style(selector, property)
    evaluate_script("getComputedStyle(document.querySelector('#{selector}')).#{property}")
  end
end
