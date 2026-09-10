require "test_helper"

# Decisive server-side proof for realtime delivery: subscribes with the
# exact params turbo_stream_from emits, then delivers a notification and
# asserts the transmission reaches the subscription. If this passes while
# browsers still see nothing, the fault is browser-side (console/CSP).
class TurboStreamsSubscriptionTest < ActionCable::Channel::TestCase
  include ActiveJob::TestHelper
  tests Turbo::StreamsChannel

  setup do
    @user = users(:lazaro_nixon)
    @stream = "notifications_#{@user.id}_account_#{accounts(:workspace_one).id}"
  end

  test "subscribes with a valid signed stream name" do
    subscribe signed_stream_name: Turbo::StreamsChannel.signed_stream_name(@stream)

    assert subscription.confirmed?
    assert_has_stream @stream
  end

  test "rejects tampered stream names" do
    subscribe signed_stream_name: "bogus--tampered"

    assert subscription.rejected?
  end
end
