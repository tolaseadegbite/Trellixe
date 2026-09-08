require "application_system_test_case"

# The landing hero carries a large soft product shadow; on narrow screens
# its blur must not widen the document into a sideways scroll.
class PagesTest < ApplicationSystemTestCase
  test "landing page has no horizontal overflow on phones" do
    visit root_path
    assert_text "No visitor falls through the cracks."

    page.driver.browser.manage.window.resize_to(390, 844)

    overflow = page.evaluate_script("document.documentElement.scrollWidth - window.innerWidth")
    assert overflow <= 0, "expected no x-overflow, got #{overflow}px"
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end
end
