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
    # Generous wait: cold headless browsers stall on first paint.
    assert_text "Today's follow-ups", wait: 10
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

  test "strip names teammate owners and limits Log to own rows" do
    other = User.new(email: "teammate@example.com", password: "Secret1*3*5*")
    other.save!(validate: false)
    event = accounts(:workspace_one).events.create!(name: "Extra Outreach",
      starts_at: 1.day.from_now, duration_in_minutes: 60)
    invitation = Invitation.create!(contact: @contact, event: event)
    invitation.follow_up_tasks.create!(user: other, due_at: 1.day.from_now)

    visit contact_url(@contact)

    within(find("li", text: other.full_name)) do
      assert_no_selector "a", text: "Log"
    end
    within(find("li", text: "You")) do
      assert_selector "a", text: "Log"
    end
    assert_text "View all in queue"
  end

  test "strip rows show due state with event-locked logging" do
    visit contact_url(@contact)

    assert_text "OPEN FOLLOW-UPS"
    assert_text "Due"
    click_on "Log", match: :first

    within("dialog[open]") do
      assert_text "For #{follow_up_tasks(:three).invitation.event.name}"
      assert_no_select "Related event"
      fill_in "What happened?", with: "Called from the strip."
      click_on "Save log"
    end

    assert_text "Interaction logged"
    assert_text "Called from the strip."
  end

  test "log-less contact renders empty state with generic logging" do    fresh = Contact.create!(first_name: "NoLog", last_name: "Person",
      owner: accounts(:workspace_one), creator: @user)

    visit contact_url(fresh)
    click_on "Log your first interaction"

    within("dialog[open]") do
      assert_select "Related event"
      fill_in "What happened?", with: "First ever call."
      click_on "Save log"
    end

    assert_text "Interaction logged"
    assert_text "First ever call."
  end

  test "empty history with only teammate tasks shows owner info, no CTA" do
    other = User.new(email: "teammate2@example.com", password: "Secret1*3*5*")
    other.save!(validate: false)
    fresh = Contact.create!(first_name: "NoLog", last_name: "Mate",
      owner: accounts(:workspace_one), creator: @user)
    event = accounts(:workspace_one).events.create!(name: "Extra Outreach",
      starts_at: 1.day.from_now, duration_in_minutes: 60)
    invitation = Invitation.create!(contact: fresh, event: event)
    invitation.follow_up_tasks.create!(user: other, due_at: 1.day.from_now)

    visit contact_url(fresh)

    assert_no_text "Log your first interaction"
    assert_text "#{other.full_name} is following up"
    assert_no_text "View all in queue"
  end

  test "events tab uses canonical event cards with status" do
    visit contact_url(@contact)
    within('[role="tablist"]') { click_on "Events" }

    assert_text invitations(:one).event.name
    assert_text "Invited"
  end

  test "tag click-through filters contacts" do
    tag = accounts(:workspace_one).tags.create!(name: "System Regulars")
    ContactTag.create!(contact: @contact, tag: tag)

    visit tags_url
    assert_text "System Regulars"
    click_on "System Regulars"

    assert_text @contact.full_name
  end

  test "mobile header toggle flips color scheme twice" do
    visit dashboard_path
    page.driver.browser.manage.window.resize_to(390, 844)

    before = find("body")["data-color-scheme"]
    flipped = before == "dark" ? "light" : "dark"

    click_on "Toggle light / dark mode"
    assert_selector "body[data-color-scheme=\"#{flipped}\"]"

    click_on "Toggle light / dark mode"
    assert_selector "body[data-color-scheme=\"#{before}\"]"
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end
end
