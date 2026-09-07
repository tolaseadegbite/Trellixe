require "application_system_test_case"

class EventsTest < ApplicationSystemTestCase
  setup do
    @user = users(:lazaro_nixon)
    @event = events(:one)
    visit sign_in_url
    fill_in "Email", with: @user.email
    fill_in "Password", with: "Secret1*3*5*"
    click_on "Sign in"
    # Wait for the authenticated render (server HTML, no JS dependency)
    # before navigating — POST+redirect otherwise races the next visit.
    assert_text "Today's follow-ups"
  end

  test "visiting the index" do
    visit events_url
    assert_selector "h1", text: /Events/
  end

  test "should create event" do
    visit events_url
    click_on "New event", match: :first

    fill_in "Name", with: "System Sunday Service"
    # Native datetime-local inputs reject keystroke fills in headless Chrome;
    # set the value programmatically (wire format) and notify listeners.
    starts_at = 3.days.from_now.strftime("%Y-%m-%dT%H:%M")
    page.execute_script(
      "const el = document.getElementById('event_starts_at');" \
      "el.value = '#{starts_at}';" \
      "el.dispatchEvent(new Event('input', { bubbles: true }));" \
      "el.dispatchEvent(new Event('change', { bubbles: true }));"
    )
    fill_in "Duration in minutes", with: 120
    click_on "Create event"

    assert_text "successfully"
  end

  test "should update Event" do
    visit event_url(@event)
    click_on "Edit", match: :first

    fill_in "Name", with: "Updated Service"
    click_on "Save changes"

    assert_text "successfully updated"
  end

  test "should destroy Event" do
    visit events_url
    first("span[data-controller='popover'] button").click
    click_on "Delete"
    within("dialog[open]") { click_on "Delete" }

    assert_text "successfully destroyed"
  end
end
