class Event < ApplicationRecord
  belongs_to :owner, polymorphic: true

  validates :name, :starts_at, :duration_in_minutes, presence: true
  validates :starts_at, presence: true
  validates :duration_in_minutes, presence: true, numericality: { greater_than: 0 }

  has_many :invitations, dependent: :destroy
  has_many :invited_contacts, through: :invitations, source: :contact
  has_many :follow_up_tasks, through: :invitations
  has_many :interaction_logs, through: :follow_up_tasks

  # This is a "virtual attribute". It feels like a database column, but it's calculated.
  def ends_at
    starts_at + duration_in_minutes.minutes
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[ id name starts_at duration_in_minutes owner ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[ invited_contacts ]
  end

  attr_accessor :contact_ids

  after_create :create_invitations_for_contacts
  after_update :create_invitations_for_contacts

  def invitation_summary
    all_invites = invitations.loaded? ? invitations : invitations.to_a

    {
      total:    all_invites.size,
      attended: all_invites.count { |i| i.attended? }
    }
  end


  private

  def create_invitations_for_contacts
    contact_ids&.reject(&:blank?)&.each do |contact_id|
      self.invitations.create(contact_id: contact_id)
    end
  end
end
