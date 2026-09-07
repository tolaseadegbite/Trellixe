require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get root_url
    assert_response :success
  end

  test "should get pricing" do
    get pricing_url
    assert_response :success
  end

  test "should get documentation" do
    get documentation_url
    assert_response :success
  end

  test "should get help" do
    get help_url
    assert_response :success
  end

  test "should get privacy" do
    get privacy_url
    assert_response :success
  end

  test "should get contact" do
    get contact_us_url
    assert_response :success
  end
end
