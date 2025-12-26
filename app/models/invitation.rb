class Invitation < ApplicationRecord
  belongs_to :contact
  belongs_to :event
  has_many :follow_up_tasks
  has_many :interaction_logs, through: :follow_up_tasks

  enum :status, {
    invited: 0,
    attended: 1
  }

  validates :status, presence: true
  validates :contact_id, uniqueness: { scope: :event_id }

  def self.ransackable_attributes(auth_object = nil)
    # Allow searching by status and event_id
    %w[status event_id]
  end

  def self.ransackable_associations(auth_object = nil)
    # Allow searching through the associated contact
    %w[contact event]
  end
end
