class Account < ApplicationRecord
  include PublicIdentifiable
  has_public_id prefix: "acct"

  # Multitenancy
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :team_invitations, dependent: :destroy

  # Trellixe Domain Data (Polymorphic Ownership)
  has_many :contacts, as: :owner, dependent: :destroy
  has_many :events, as: :owner, dependent: :destroy
  has_many :tags, as: :owner, dependent: :destroy
  has_many :event_series, as: :owner, dependent: :destroy

  # Through associations for deep querying
  has_many :invitations, through: :events
  has_many :follow_up_tasks, through: :invitations

  # Notifications
  has_many :noticed_events, as: :record, dependent: :destroy, class_name: "Noticed::Event"
  has_many :notifications, through: :noticed_events, class_name: "Noticed::Notification"

  validates :name, presence: true

  def personal?
    # A workspace is "personal" if the current user is the only admin/member
    memberships.count == 1 && memberships.first.admin?
  end

  def seats_used
    memberships.count + team_invitations.count
  end

  def seat_limit_reached?
    seats_used >= seat_limit
  end
end
