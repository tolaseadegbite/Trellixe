require "test_helper"

class TodoTest < ActiveSupport::TestCase
  setup do
    Current.account = accounts(:workspace_one)
    @account = accounts(:workspace_one)
    @admin = users(:lazaro_nixon)
    @member = User.create!(email: "member@example.com", password: "Secret1*3*5*", verified: true)
    @member.memberships.create!(account: @account, role: :member)
    @outsider = User.create!(email: "outsider@example.com", password: "Secret1*3*5*", verified: true)
    @contact = contacts(:one)
  end

  test "requires a title" do
    todo = @account.todos.new(user: @admin, creator: @admin)

    assert_not todo.valid?
    assert_includes todo.errors[:title], "can't be blank"
  end

  test "defaults to shared with zero progress" do
    todo = @account.todos.create!(title: "Pray", user: @admin, creator: @admin)

    assert_predicate todo, :shared?
    assert_equal 0, todo.progress_count
    assert_not todo.goal?
    assert_not todo.completed?
  end

  test "goal predicate and progress bounds" do
    todo = @account.todos.new(title: "Win souls", user: @admin, creator: @admin,
      target_count: 5, progress_count: 6)

    assert_predicate todo, :goal?
    assert_not todo.valid?
    assert_includes todo.errors[:progress_count], "can't exceed the target"
  end

  test "target must be positive" do
    todo = @account.todos.new(title: "Win souls", user: @admin, creator: @admin, target_count: 0)

    assert_not todo.valid?
  end

  test "assignee must belong to the workspace" do
    todo = @account.todos.new(title: "Visit", user: @outsider, creator: @admin)

    assert_not todo.valid?
    assert_includes todo.errors[:user], "must be a workspace member"
  end

  test "personal todo belongs to its creator" do
    todo = @account.todos.new(title: "Private", user: @member, creator: @admin, visibility: :personal)

    assert_not todo.valid?
    assert_includes todo.errors[:user], "personal todos belong to their creator"
  end

  test "overdue only when open with a past due date" do
    open_overdue = @account.todos.new(title: "Late", user: @admin, creator: @admin, due_at: 1.day.ago)
    done_overdue = @account.todos.new(title: "Done", user: @admin, creator: @admin,
      due_at: 1.day.ago, completed_at: 1.hour.ago)
    future = @account.todos.new(title: "Soon", user: @admin, creator: @admin, due_at: 1.day.from_now)
    undated = @account.todos.new(title: "Someday", user: @admin, creator: @admin)

    assert_predicate open_overdue, :overdue?
    assert_not done_overdue.overdue?
    assert_not future.overdue?
    assert_not undated.overdue?
  end

  test "syncs contacts from contact_ids on create and replace on update" do
    other = contacts(:two)

    todo = @account.todos.create!(title: "Visit", user: @admin, creator: @admin,
      contact_ids: [ @contact.id, other.id ])
    assert_equal [ @contact.id, other.id ].sort, todo.contacts.pluck(:id).sort

    todo.update!(contact_ids: [ other.id ])
    assert_equal [ other.id ], todo.reload.contacts.pluck(:id)
  end

  test "drops cross-account contact ids" do
    foreign = Contact.create!(owner: accounts(:workspace_two), creator: @admin, first_name: "Far")

    todo = @account.todos.create!(title: "Visit", user: @admin, creator: @admin,
      contact_ids: [ @contact.id, foreign.id ])
    assert_equal [ @contact.id ], todo.contacts.pluck(:id)
  end

  test "team-wide todo needs no assignee" do
    todo = @account.todos.new(title: "Pray", user: nil, creator: @admin)

    assert_predicate todo, :valid?
  end

  test "participation logs once per member" do
    todo = @account.todos.create!(title: "Pray", user: nil, creator: @admin)
    todo.todo_participations.create!(user: @member)
    duplicate = todo.todo_participations.new(user: @member)

    assert_not duplicate.valid?
    assert todo.participated?(@member)
    assert_not todo.participated?(@outsider)
  end

  test "destroy cascades todo_contacts" do
    todo = @account.todos.create!(title: "Visit", user: @admin, creator: @admin,
      contact_ids: [ @contact.id ])

    assert_difference -> { TodoContact.count }, -1 do
      todo.destroy!
    end
  end
end
