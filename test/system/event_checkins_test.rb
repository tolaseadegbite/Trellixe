require "application_system_test_case"

class EventCheckinsTest < ApplicationSystemTestCase
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

  test "tapping a row checks in and updates the counter" do
    visit event_path(@event, mode: "checkin")

    assert_text "1 of 2 checked in"
    assert_text "Tap to check in"

    click_on "Adaeze Okafor"

    assert_text "2 of 2 checked in"
    assert_text "Checked in — tap to undo"
  end

  test "tapping a checked-in row undoes it" do
    visit event_path(@event, mode: "checkin")
    click_on "Adaeze Okafor"
    assert_text "2 of 2 checked in"

    click_on "Adaeze Okafor"

    assert_text "1 of 2 checked in"
    assert_text "Tap to check in"
  end
end
