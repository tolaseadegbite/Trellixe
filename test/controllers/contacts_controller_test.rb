require "test_helper"

class ContactsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:lazaro_nixon)
    sign_in_as(@user)
    @contact = contacts(:one)
  end

  test "should get index" do
    get contacts_url
    assert_response :success
  end

  test "should get new" do
    get new_contact_url
    assert_response :success
  end

  test "should create contact via turbo stream" do
    assert_difference("Contact.count") do
      post contacts_url, params: {
        contact: {
          first_name: "Funmi",
          last_name: "Bello",
          email: "funmi@example.com",
          phone_number: "+2348077778888",
          how_we_met: "Met at Saturday outreach."
        }
      }, as: :turbo_stream
    end

    assert_response :success
  end

  test "should show contact" do
    get contact_url(@contact)
    assert_response :success
  end

  test "should get edit" do
    get edit_contact_url(@contact)
    assert_response :success
  end

  test "should update contact via turbo stream" do
    patch contact_url(@contact), params: {
      contact: { first_name: "Updated", how_we_met: "Updated context." }
    }, as: :turbo_stream
    assert_response :success
  end

  test "should destroy contact" do
    assert_difference("Contact.count", -1) do
      delete contact_url(@contact)
    end

    assert_redirected_to contacts_url
  end
end
