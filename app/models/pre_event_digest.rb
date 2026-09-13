class PreEventDigest < ApplicationRecord
  belongs_to :event
  belongs_to :user

  validates :fire_at, presence: true

  # Ensures one pending digest per (event, volunteer), firing at the
  # earliest needed slot. Called on every invitation creation path
  # (model callback covers .create!; insert_all sites call explicitly).
  # Later invitees join the pending digest; already-sent rows never match
  # (partial unique index), so post-send invitees start a fresh digest.
  def self.schedule_for(invitation)
    event = invitation.event
    owner = event.owner
    return unless owner.is_a?(Account) && owner.pre_event_enabled?

    volunteer = invitation.contact.creator
    return if volunteer.nil? || !owner.users.exists?(volunteer.id)

    zone = volunteer.time_zone.presence || "UTC"
    fire = owner.pre_reminder_fire_at(invitation.created_at, event.starts_at, zone)
    return if fire == :skip

    fire_at = fire == :immediate ? Time.current : fire
    digest = where(event: event, user: volunteer, sent_at: nil)
             .create_or_find_by!(fire_at: fire_at)
    # Enqueue only for fresh rows — or when a policy change moved an
    # existing pending digest later than a newly needed slot. Superseded
    # jobs exit on the sent check.
    if digest.previously_new_record? || fire_at < digest.fire_at
      digest.update!(fire_at: fire_at) unless digest.previously_new_record?
      if fire == :immediate
        PreEventDigestJob.perform_later(digest)
      else
        PreEventDigestJob.set(wait_until: digest.fire_at).perform_later(digest)
      end
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end
