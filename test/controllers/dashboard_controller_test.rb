require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:workspace_one)
    @admin = users(:lazaro_nixon)
    @member = User.create!(email: "member@example.com", password: "Secret1*3*5*", verified: true)
    @member.memberships.create!(account: @account, role: :member)
    sign_in_as(@admin)
  end

  test "dashboard lists my due todos soonest first with counts" do
    @account.todos.create!(title: "Later", user: @admin, creator: @admin, due_at: 3.days.from_now)
    @account.todos.create!(title: "Sooner", user: @admin, creator: @admin, due_at: 1.hour.from_now)
    @account.todos.create!(title: "Undated", user: @admin, creator: @admin)
    @account.todos.create!(title: "Done dated", user: @admin, creator: @admin,
      due_at: 1.hour.from_now, completed_at: 1.hour.ago)

    get dashboard_url

    assert_response :success
    assert_match "Due todos", response.body
    assert_match "Sooner", response.body
    assert_match "Later", response.body
    assert_no_match "Undated", response.body
    assert_no_match "Done dated", response.body
    assert response.body.index("Sooner") < response.body.index("Later")
  end

  test "dashboard hides other members personal todos" do
    @account.todos.create!(title: "Secret", user: @member, creator: @member,
      visibility: :personal, due_at: 1.hour.from_now)

    get dashboard_url

    assert_response :success
    assert_no_match "Secret", response.body
  end

  test "dashboard shows goal counts on goal todos" do
    @account.todos.create!(title: "Win souls", user: @admin, creator: @admin,
      due_at: 2.days.from_now, target_count: 20, progress_count: 7)

    get dashboard_url

    assert_response :success
    assert_match "7/20", response.body
  end

  test "dashboard includes team-wide todos" do
    @account.todos.create!(title: "All pray", user: nil, creator: @admin, due_at: 2.hours.from_now)
    sign_in_as(@member)

    get dashboard_url

    assert_response :success
    assert_match "All pray", response.body
  end
end
