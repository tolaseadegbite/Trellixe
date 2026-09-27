require "application_system_test_case"

class TodosTest < ApplicationSystemTestCase
  setup do
    @user = users(:lazaro_nixon)
    @contact = contacts(:one)
    visit sign_in_url
    fill_in "Email", with: @user.email
    fill_in "Password", with: "Secret1*3*5*"
    click_on "Sign in"
    # Wait for the authenticated render (server HTML, no JS dependency)
    # before navigating — POST+redirect otherwise races the next visit.
    assert_text "Today's follow-ups", wait: 10
  end

  test "admin creates a shared todo linked to a contact" do
    visit todos_url
    click_on "New todo"

    within("dialog[open]") do
      fill_in "Title", with: "Pray for Ada"
      check @contact.full_name
      click_on "Create todo"
    end

    assert_text "Todo created"
    assert_text "Pray for Ada"
  end

  test "completing a todo from the list" do
    accounts(:workspace_one).todos.create!(title: "Call Ada", user: @user, creator: @user)

    visit todos_url
    find("button[title='Mark complete']").click

    assert_text "Todo completed"
  end

  test "member logs participation on a team-wide todo" do
    accounts(:workspace_one).todos.create!(title: "Pray for all", user: nil, creator: @user)

    visit todos_url
    click_on "I participated"

    assert_text "Participation logged"
    assert_text "You participated"
  end

  test "due date picker opens inside the modal, placed under the field, and fills it" do
    visit todos_url
    click_on "New todo"

    within("dialog[open] #todo_due_field") do
      find("input[type='text']").click
    end
    assert_selector "dialog[open] .flatpickr-calendar.open", wait: 10

    geometry = evaluate_script(<<~JS)
      (() => {
        const dialog = document.querySelector("dialog[open]");
        const input = dialog.querySelector("#todo_due_field input[type='text']");
        const calendar = dialog.querySelector(".flatpickr-calendar.open");
        const d = dialog.getBoundingClientRect(), i = input.getBoundingClientRect(), c = calendar.getBoundingClientRect();
        return { inDialog: c.left >= d.left && c.right <= d.right && c.top >= d.top && c.bottom <= d.bottom,
                 belowInput: c.top >= i.bottom - 16 && c.top <= i.bottom + 120 &&
                             Math.abs(c.left - i.left) <= 8 };
      })()
    JS
    assert geometry["inDialog"], "calendar escapes the dialog"
    assert geometry["belowInput"], "calendar is not under the field"

    find("dialog[open] .flatpickr-calendar.open .flatpickr-day:not(.prevMonthDay):not(.nextMonthDay)", match: :first).click

    within("dialog[open] #todo_due_field") do
      assert_not_equal "", find("input[type='text']").value
    end
  end

  test "header button and mobile action both open the todo modal" do
    visit todos_url

    assert_selector "a[href='#{new_todo_path}']", text: "New todo"
    assert_selector "a[aria-label='New todo']", visible: :all
  end

  test "dashboard shows a due todo with a ticking label" do
    accounts(:workspace_one).todos.create!(title: "Dashboard due", user: @user, creator: @user,
      due_at: 2.hours.from_now)

    visit dashboard_url

    assert_text "Due todos"
    assert_text "Dashboard due"
    assert_text(/Due in \d+h/, wait: 10)
  end

  test "member personal todo is invisible to admin" do
    member = User.new(email: "private@example.com", password: "Secret1*3*5*")
    member.save!(validate: false)
    member.memberships.create!(account: accounts(:workspace_one), role: :member)
    accounts(:workspace_one).todos.create!(title: "Hidden private task",
      user: member, creator: member, visibility: :personal)

    visit todos_url

    assert_no_text "Hidden private task"
  end
end
