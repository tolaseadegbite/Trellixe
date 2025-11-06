class FollowUpTask < ApplicationRecord
  # == Associations ===============
  belongs_to :invitation
  belongs_to :user

  has_many :interaction_logs, dependent: :destroy
  has_one :contact, through: :invitation
  has_one :event, through: :invitation

  after_create_commit :schedule_reminder

  # --- RANSACK CONFIGURATION ---

  def self.ransackable_attributes(auth_object = nil)
    # We still need `due_at` for our date-based searches.
    [ "due_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "contact", "event", "invitation" ]
  end

  private

  # This method will be called after a new task is saved to the database.
  def schedule_reminder
    FollowUpTaskNotifier
      .with(task: self)
      .deliver_later(
        user, # The recipient of the notification
        wait_until: due_at # The magic! Noticed will schedule the job for this time.
      )
  end
end
