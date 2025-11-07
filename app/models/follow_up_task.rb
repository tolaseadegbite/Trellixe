class FollowUpTask < ApplicationRecord
  # == Associations ===============
  belongs_to :invitation
  belongs_to :user

  has_many :interaction_logs, dependent: :destroy
  has_one :contact, through: :invitation
  has_one :event, through: :invitation

  after_create_commit :schedule_first_reminder

  # --- RANSACK CONFIGURATION ---

  def self.ransackable_attributes(auth_object = nil)
    # We still need `due_at` for our date-based searches.
    [ "due_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "contact", "event", "invitation" ]
  end

  private

  def schedule_first_reminder
    FollowUpReminderJob.set(wait_until: due_at).perform_later(self)
  end
end
