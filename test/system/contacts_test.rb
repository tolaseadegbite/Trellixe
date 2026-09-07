require "application_system_test_case"

class ContactsTest < ApplicationSystemTestCase
  setup do
    @user = users(:lazaro_nixon)
    @contact = contacts(:one)
    visit sign_in_url
    fill_in "Email", with: @user.email
    fill_in "Password", with: "Secret1*3*5*"
    click_on "Sign in"
    # Wait for the authenticated render (server HTML, no JS dependency)
    # before navigating — POST+redirect otherwise races the next visit.
    assert_text "Today's follow-ups"
  end

  test "visiting the index" do
    visit contacts_url
    assert_selector "h1", text: /Contacts/
  end

  test "should create contact" do
    visit contacts_url
    click_on "New contact", match: :first

    fill_in "First name", with: "Funmi"
    fill_in "Last name", with: "Bello"
    fill_in "Email", with: "funmi-system@example.com"
    fill_in "Phone number", with: "+2348077778888"
    click_on "Add contact"

    assert_text "Contact created"
  end

  test "should update Contact" do
    visit contact_url(@contact)
    click_on "Edit", match: :first

    fill_in "First name", with: "Updated"
    click_on "Save changes"

    assert_text "successfully updated"
  end

  test "should destroy Contact" do
    visit contacts_url
    first("span[data-controller='popover'] button").click
    click_on "Delete"
    within("dialog[open]") { click_on "Delete" }

    assert_text "successfully destroyed"
  end
end
