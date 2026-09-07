class Invitation < ApplicationRecord
  belongs_to :contact
  belongs_to :event
  has_many :follow_up_tasks, dependent: :destroy
  has_many :interaction_logs, through: :follow_up_tasks

  enum :status, {
    invited: 0,
    attended: 1,
    declined: 2
  }

  validates :status, presence: true
  validates :contact_id, uniqueness: { scope: :event_id }

  # Undoing attendance cancels the work it spawned. Only pending tasks go —
  # completed work and its logs are immutable history and stay.
  after_update :remove_pending_follow_ups, if: :saved_change_to_status?

  def self.ransackable_attributes(auth_object = nil)
    # Allow searching by status and event_id
    %w[status event_id]
  end

  def self.ransackable_associations(auth_object = nil)
    # Allow searching through the associated contact
    %w[contact event]
  end

  private

  def remove_pending_follow_ups
    return if attended?
    return unless status_before_last_save == "attended"

    follow_up_tasks.pending.destroy_all
  end
end
