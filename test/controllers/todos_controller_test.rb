require "test_helper"

class TodosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:workspace_one)
    @admin = users(:lazaro_nixon)
    @member = User.create!(email: "member@example.com", password: "Secret1*3*5*", verified: true)
    @member.memberships.create!(account: @account, role: :member)
    @other = User.create!(email: "other@example.com", password: "Secret1*3*5*", verified: true)
    @other.memberships.create!(account: @account, role: :member)
    sign_in_as(@admin)
  end

  test "admin creates shared todo assigned to a member with contacts" do
    assert_difference -> { Todo.count }, 1 do
      post todos_url, params: {
        todo: { title: "Visit", visibility: "shared", user_id: @member.id,
                contact_ids: [ contacts(:one).id, contacts(:two).id ] }
      }, as: :turbo_stream
    end

    assert_response :success
    todo = Todo.last
    assert_predicate todo, :shared?
    assert_equal @member, todo.user
    assert_equal @admin, todo.creator
    assert_equal 2, todo.contacts.count
  end

  test "member creation is forced personal to self" do
    sign_in_as(@member)

    post todos_url, params: {
      todo: { title: "Mine", visibility: "shared", user_id: @admin.id }
    }, as: :turbo_stream

    assert_response :success
    todo = Todo.last
    assert_predicate todo, :personal?
    assert_equal @member, todo.user
  end

  test "index hides other members personal todos, even from admin" do
    @account.todos.create!(title: "Secret", user: @member, creator: @member, visibility: :personal)
    @account.todos.create!(title: "Shared work", user: @member, creator: @admin)

    get todos_url
    assert_response :success
    assert_match "Shared work", response.body
    assert_no_match "Secret", response.body
  end

  test "member sees own personal todos" do
    sign_in_as(@member)
    @account.todos.create!(title: "Secret", user: @member, creator: @member, visibility: :personal)

    get todos_url
    assert_response :success
    assert_match "Secret", response.body
  end

  test "assignee completes shared todo" do
    todo = @account.todos.create!(title: "Visit", user: @member, creator: @admin)
    sign_in_as(@member)

    patch toggle_complete_todo_url(todo), as: :turbo_stream

    assert_response :success
    assert_predicate todo.reload, :completed?
  end

  test "non-assignee member cannot mutate shared todo" do
    todo = @account.todos.create!(title: "Visit", user: @member, creator: @admin)
    sign_in_as(@other)

    patch toggle_complete_todo_url(todo), as: :turbo_stream

    assert_redirected_to todos_path
    assert_not todo.reload.completed?
  end

  test "non-admin cannot destroy shared todo" do
    todo = @account.todos.create!(title: "Visit", user: @member, creator: @admin)
    sign_in_as(@member)

    assert_no_difference -> { Todo.count } do
      delete todo_url(todo), as: :turbo_stream
    end
  end

  test "member destroys own personal todo" do
    sign_in_as(@member)
    todo = @account.todos.create!(title: "Mine", user: @member, creator: @member, visibility: :personal)

    assert_difference -> { Todo.count }, -1 do
      delete todo_url(todo), as: :turbo_stream
    end

    assert_response :success
  end

  test "cross-account todo is not reachable" do
    neighbor = User.create!(email: "neighbor@example.com", password: "Secret1*3*5*", verified: true)
    neighbor.memberships.create!(account: accounts(:workspace_two), role: :member)
    foreign = accounts(:workspace_two).todos.create!(
      title: "Elsewhere", user: neighbor, creator: neighbor)

    patch toggle_complete_todo_url(foreign), as: :turbo_stream

    assert_response :not_found
  end

  test "goal progress steps within bounds" do
    todo = @account.todos.create!(title: "Win souls", user: @member, creator: @admin, target_count: 2)

    patch step_progress_todo_url(todo), params: { delta: 5 }, as: :turbo_stream
    assert_equal 1, todo.reload.progress_count

    patch step_progress_todo_url(todo), params: { delta: 5 }, as: :turbo_stream
    assert_equal 2, todo.reload.progress_count

    patch step_progress_todo_url(todo), params: { delta: -5 }, as: :turbo_stream
    assert_equal 1, todo.reload.progress_count
  end

  test "assignee cannot edit shared todo fields" do
    todo = @account.todos.create!(title: "Visit", user: @member, creator: @admin)
    sign_in_as(@member)

    patch todo_url(todo), params: { todo: { title: "Hijacked" } }, as: :turbo_stream

    assert_redirected_to todos_path
    assert_equal "Visit", todo.reload.title
  end

  test "team-wide todo is created unassigned and closable only by admin" do
    post todos_url, params: {
      todo: { title: "Pray", visibility: "shared", user_id: "" }
    }, as: :turbo_stream

    assert_response :success
    todo = Todo.last
    assert_nil todo.user

    sign_in_as(@member)
    patch toggle_complete_todo_url(todo), as: :turbo_stream
    assert_redirected_to todos_path
    assert_not todo.reload.completed?

    sign_in_as(@admin)
    patch toggle_complete_todo_url(todo), as: :turbo_stream
    assert_response :success
    assert_predicate todo.reload, :completed?
  end

  test "member logs and removes participation on shared todo" do
    todo = @account.todos.create!(title: "Pray", user: nil, creator: @admin)
    sign_in_as(@member)

    assert_difference -> { TodoParticipation.count }, 1 do
      patch participate_todo_url(todo), as: :turbo_stream
    end
    assert_response :success
    assert todo.reload.participated?(@member)

    assert_difference -> { TodoParticipation.count }, -1 do
      patch participate_todo_url(todo), as: :turbo_stream
    end
    assert_response :success
    assert_not todo.reload.participated?(@member)
  end

  test "participation is denied on personal todos" do
    sign_in_as(@member)
    todo = @account.todos.create!(title: "Mine", user: @member, creator: @member, visibility: :personal)

    assert_no_difference -> { TodoParticipation.count } do
      patch participate_todo_url(todo), as: :turbo_stream
    end

    assert_redirected_to todos_path
  end

  test "owner steps progress on own personal goal" do
    sign_in_as(@member)
    todo = @account.todos.create!(title: "Read John", user: @member, creator: @member,
      visibility: :personal, target_count: 3)

    patch step_progress_todo_url(todo), params: { delta: 1 }, as: :turbo_stream

    assert_response :success
    assert_equal 1, todo.reload.progress_count
  end

  test "member steps progress on team-wide goal" do
    todo = @account.todos.create!(title: "Read John", user: nil, creator: @admin, target_count: 3)
    sign_in_as(@member)

    patch step_progress_todo_url(todo), params: { delta: 1 }, as: :turbo_stream

    assert_response :success
    assert_equal 1, todo.reload.progress_count
  end

  test "cross-account contact ids are dropped on create" do
    foreign = Contact.create!(owner: accounts(:workspace_two), creator: @admin, first_name: "Far")

    post todos_url, params: {
      todo: { title: "Visit", visibility: "shared", user_id: @member.id,
              contact_ids: [ contacts(:one).id, foreign.id ] }
    }, as: :turbo_stream

    assert_response :success
    assert_equal [ contacts(:one).id ], Todo.last.contacts.pluck(:id)
  end
end
