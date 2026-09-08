require "test_helper"

class InteractionLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:lazaro_nixon)
    sign_in_as(@user)
    @contact = contacts(:one)
  end

  test "should get new standalone log for contact" do
    get new_contact_interaction_log_url(@contact)
    assert_response :success
  end

  test "should get new with preset locked event" do
    get new_contact_interaction_log_url(@contact, event_id: events(:one).id)

    assert_response :success
    assert_select "input[type=hidden][name=?]", "interaction_log[event_id]"
    assert_select "strong", events(:one).name
  end

  test "should 404 for preset of unknown event" do
    get new_contact_interaction_log_url(@contact, event_id: 999_999)

    assert_response :not_found
  end

  test "should create standalone log via turbo stream without a task" do
    assert_difference("InteractionLog.count") do
      post contact_interaction_logs_url(@contact),
        params: { interaction_log: { note: "Called, great chat." } }, as: :turbo_stream
    end

    assert_response :success
    log = InteractionLog.last
    assert_nil log.follow_up_task
    assert_equal @contact, log.contact
    assert_equal @user, log.user
  end

  test "should create standalone log via html" do
    post contact_interaction_logs_url(@contact),
      params: { interaction_log: { note: "Met for coffee." } }

    assert_redirected_to contact_url(@contact)
  end

  test "should reject blank standalone note" do
    assert_no_difference("InteractionLog.count") do
      post contact_interaction_logs_url(@contact),
        params: { interaction_log: { note: "" } }, as: :turbo_stream
    end

    assert_response :unprocessable_entity
  end

  test "should attach related event when provided" do
    event = events(:one)

    post contact_interaction_logs_url(@contact),
      params: { interaction_log: { note: "Saw at the service.", event_id: event.id } }, as: :turbo_stream

    assert_response :success
    assert_equal event, InteractionLog.last.event
  end

  test "should 404 for unknown event id" do
    assert_no_difference("InteractionLog.count") do
      post contact_interaction_logs_url(@contact),
        params: { interaction_log: { note: "Sneaky.", event_id: 999_999 } }
    end

    assert_response :not_found
  end

  test "should not log for another account contact" do
    other = accounts(:workspace_two).contacts.create!(first_name: "Sneaky", creator: @user)

    assert_no_difference("InteractionLog.count") do
      post contact_interaction_logs_url(other),
        params: { interaction_log: { note: "Nope." } }
    end

    assert_response :not_found
  end
end
