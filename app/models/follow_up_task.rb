class FollowUpTask < ApplicationRecord
  belongs_to :invitation
  belongs_to :user

  has_many :interaction_logs, dependent: :destroy
  has_one :contact, through: :invitation
  has_one :event, through: :invitation

  after_create_commit :schedule_first_reminder
  # Cancelled work must not leave actionable reminders behind: deleting the
  # task removes its notifications too (marking read is for completed work,
  # which keeps its task row). Runs on every destroy path — undo, guest
  # removal, workspace deletion.
  before_destroy :remove_related_notifications

  scope :for_account, ->(account) {
    joins(invitation: :event).where(events: { owner_type: "Account", owner_id: account.id })
  }

  scope :pending, -> { where(completed_at: nil) }

  def self.ransackable_attributes(auth_object = nil)
    [ "due_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "contact", "event", "invitation" ]
  end

  private

  def schedule_first_reminder
    FollowUpReminderJob.set(wait_until: due_at).perform_later(self)
  end

  def remove_related_notifications
    event_ids = Noticed::Event.where(type: "FollowUpTaskNotifier")
                              .where("params #>> '{task, _aj_globalid}' = ?", to_gid.to_s)
                              .pluck(:id)
    Noticed::Notification.where(event_id: event_ids).delete_all
  end
end
