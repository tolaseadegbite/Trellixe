require "test_helper"

class TodoContactTest < ActiveSupport::TestCase
  setup do
    Current.account = accounts(:workspace_one)
    @todo = accounts(:workspace_one).todos.create!(
      title: "Visit", user: users(:lazaro_nixon), creator: users(:lazaro_nixon))
  end

  test "contact links once per todo" do
    @todo.todo_contacts.create!(contact: contacts(:one))
    duplicate = @todo.todo_contacts.new(contact: contacts(:one))

    assert_not duplicate.valid?
  end

  test "todo links read back through the join" do
    @todo.todo_contacts.create!(contact: contacts(:one))

    assert_equal [ contacts(:one) ], @todo.reload.contacts
  end
end
