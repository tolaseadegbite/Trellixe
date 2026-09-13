require "test_helper"

class PreEventDigestTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = users(:lazaro_nixon)
    @account = accounts(:workspace_one)
    @event = events(:two) # Thursday Cell Meeting, 4 days out
  end

  def fresh_contact(name)
    @account.contacts.create!(first_name: name, creator: @user)
  end

  test "invitation creation schedules one digest for the creator" do
    assert_difference([ "PreEventDigest.count", "enqueued_jobs.size" ]) do
      Invitation.create!(contact: fresh_contact("Digest One"), event: @event)
    end

    digest = PreEventDigest.last
    assert_equal @event, digest.event
    assert_equal @user, digest.user
    assert_nil digest.sent_at
  end

  test "second invitee joins the pending digest without a new job" do
    Invitation.create!(contact: fresh_contact("Digest One"), event: @event)

    assert_no_difference("PreEventDigest.count") do
      assert_no_difference("enqueued_jobs.size") do
        Invitation.create!(contact: fresh_contact("Digest Two"), event: @event)
      end
    end
  end

  test "disabled policy schedules nothing" do
    @account.update!(pre_event_enabled: false)

    assert_no_difference([ "PreEventDigest.count", "enqueued_jobs.size" ]) do
      Invitation.create!(contact: fresh_contact("Digest One"), event: @event)
    end
  end

  test "job delivers one digest and marks sent" do
    invitation = Invitation.create!(contact: fresh_contact("Digest One"), event: @event)
    digest = PreEventDigest.find_by!(event: @event, user: @user)

    assert_difference("Noticed::Notification.count", 1) do
      perform_enqueued_jobs { PreEventDigestJob.perform_later(digest) }
    end

    assert_predicate digest.reload, :sent_at?
    assert_equal "Thursday Cell Meeting", digest.event.name
    assert invitation.present?
  end

  test "sent digest blocks reruns" do
    Invitation.create!(contact: fresh_contact("Digest One"), event: @event)
    digest = PreEventDigest.last
    digest.update!(sent_at: Time.current)

    assert_no_difference("Noticed::Notification.count") do
      perform_enqueued_jobs { PreEventDigestJob.perform_later(digest) }
    end
  end

  test "job exits quietly when digest gone mid-flight" do
    Invitation.create!(contact: fresh_contact("Digest Gone"), event: @event)
    stale = PreEventDigest.find(PreEventDigest.last.id)
    PreEventDigest.last.destroy!

    assert_no_difference("Noticed::Notification.count") do
      assert_nothing_raised { PreEventDigestJob.perform_now(stale) }
    end
  end
end
