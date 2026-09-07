require "application_system_test_case"

# Guards the shared search idiom every list page rides on: debounced
# search, saved-view pills, and reset.
class SearchTest < ApplicationSystemTestCase
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

  private

  # Widget-backed controls (TomSelect, flatpickr) boot asynchronously from
  # CDN modules; a first click landing before boot is silently swallowed.
  # Every list page renders a TomSelect inside its (initially closed) filter
  # panel, so its presence — visible or not — proves the JS stack
  # (importmap, Stimulus, widgets) is ready for interaction.
  def wait_for_widgets
    assert_selector ".ts-wrapper", visible: :all
  end

  test "search filters the contacts list" do
    visit contacts_url
    wait_for_widgets
    assert_text "Adaeze Okafor"
    assert_text "Daniel Adeyemi"

    fill_in "Search name, email, or context…", with: "Adaeze"

    assert_text "Found 1 contact"
    assert_text "Adaeze Okafor"
    assert_no_text "Daniel Adeyemi"
  end

  test "clearing the search clears the readout and restores the list" do
    visit contacts_url
    wait_for_widgets
    fill_in "Search name, email, or context…", with: "Adaeze"
    assert_text "Found 1 contact"

    fill_in "Search name, email, or context…", with: ""

    assert_no_text "Active:"
    assert_no_text "matching your filters"
    assert_text "Adaeze Okafor"
    assert_text "Daniel Adeyemi"
  end

  test "saved views and reset" do
    visit contacts_url
    wait_for_widgets

    click_on "New this week"
    assert_text "Found 2 contacts"

    click_on "Filters"
    click_on "Reset"
    # No page reload: the panel stays open and the inputs are cleared.
    assert_text "Reset"
    assert_equal "", find_field("Search name, email, or context…").value
    assert_text "Adaeze Okafor"
    assert_text "Daniel Adeyemi"
    assert_no_text "matching your filters"
  end

  test "dismissing a single pill restores the list without reload" do
    visit contacts_url
    wait_for_widgets
    fill_in "Search name, email, or context…", with: "Adaeze"
    assert_text "Found 1 contact"

    click_on "Filters"
    find("[title='Remove filter']").click

    assert_no_text "Active:"
    assert_text "Adaeze Okafor"
    assert_text "Daniel Adeyemi"
  end

  test "events list shows its own active readout" do
    visit events_url
    wait_for_widgets

    fill_in "Search events by name…", with: "Sunday"

    assert_text "Active:"
    assert_text "Sunday"
    assert_no_text "Thursday Cell Meeting"
  end

  test "filtering keeps the panel open" do
    visit follow_up_tasks_url
    wait_for_widgets
    click_on "Filters"

    find(".ts-control").click
    find(".ts-dropdown .option", text: "Sunday Service", match: :first).click

    assert_text "Daniel Adeyemi"
    assert_no_text "Adaeze Okafor"
    assert_text "Reset"
  end

  test "navigating the date picker keeps the panel open" do
    visit events_url
    wait_for_widgets
    click_on "Filters"
    # Flatpickr builds its (hidden) calendar on boot; gate on it so the
    # assertions below observe the widget, not its absence.
    assert_selector ".flatpickr-calendar", visible: :all

    # Flatpickr converts the original input to type=hidden, so open the
    # calendar through its API, then navigate months like a user would.
    page.evaluate_script("document.getElementById('q_starts_at_gteq')._flatpickr.open()")
    find(".flatpickr-prev-month").click

    assert_text "Reset"
  end
end
