require "application_system_test_case"

class FollowUpTasksTest < ApplicationSystemTestCase
  setup do
    @user = users(:lazaro_nixon)
    visit sign_in_url
    fill_in "Email", with: @user.email
    fill_in "Password", with: "Secret1*3*5*"
    click_on "Sign in"
    # Wait for the authenticated render (server HTML, no JS dependency)
    # before navigating — POST+redirect otherwise races the next visit.
    # Generous wait: cold headless browsers stall on first paint.
    assert_text "Today's follow-ups", wait: 10
  end

  test "completing the current card advances the queue" do
    visit follow_up_tasks_url
    assert_text "Daniel Adeyemi"
    assert_text "1 of 2"

    click_on "Done"

    assert_text "Adaeze Okafor"
    assert_text "1 of 1"
  end

  test "logging a follow-up completes and advances the queue" do
    visit follow_up_tasks_url
    assert_text "Daniel Adeyemi"

    click_on "Log follow-up"
    fill_in "What happened?", with: "Called, great chat — coming Sunday."
    click_on "Save log"

    assert_text "Adaeze Okafor"
  end

  test "up-next focus moves forward and Previous moves back" do
    visit follow_up_tasks_url
    assert_text "Daniel Adeyemi"
    assert_text "1 of 2"

    click_on "Adaeze Okafor"
    assert_text "2 of 2"

    click_on "← Previous"
    assert_text "Daniel Adeyemi"
    assert_text "1 of 2"
  end
end
