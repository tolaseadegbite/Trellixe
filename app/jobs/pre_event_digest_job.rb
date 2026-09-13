class PreEventDigestJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  def perform(digest)
    # A deleted digest, event, or volunteer means there is nothing to
    # notify — exit quietly instead of retrying a job that can never
    # succeed (e.g. event destroyed with a digest still enqueued).
    digest = PreEventDigest.find(digest.id)
    event = digest.event
    volunteer = digest.user
    owner = event.owner
    return if digest.sent_at?
    return digest.update!(sent_at: Time.current) unless owner.is_a?(Account)

    invitees = event.invitations.includes(:contact)
                   .where(status: :invited)
                   .select { |i| i.contact.creator_id == volunteer.id }
    if invitees.any? && event.starts_at > Time.current
      PreEventDigestNotifier.with(
        event: event,
        event_id: event.id,
        event_name: event.name,
        invitee_count: invitees.size,
        account_id: owner.id
      ).deliver(volunteer)
    end
    digest.update!(sent_at: Time.current)
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
