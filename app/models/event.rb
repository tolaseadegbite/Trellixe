class Event < ApplicationRecord
  belongs_to :owner, polymorphic: true

  validates :name, :starts_at, :duration_in_minutes, presence: true
  validates :starts_at, presence: true
  validates :duration_in_minutes, presence: true, numericality: { greater_than: 0 }

  has_many :invitations, dependent: :destroy
  has_many :invited_contacts, through: :invitations, source: :contact
  has_many :follow_up_tasks, through: :invitations
  has_many :interaction_logs, through: :follow_up_tasks

  attr_accessor :contact_ids

  after_create :create_invitations_for_contacts
  after_update :create_invitations_for_contacts

  # --- NEW SCOPES ---

  # Helper to calculate the End Time inside the database query
  def self.sql_ends_at
    "starts_at + (duration_in_minutes * interval '1 minute')"
  end

  # Calendar Optimization: Only load events starting in the viewable range
  scope :in_range, ->(start_date, end_date) { where(starts_at: start_date..end_date) }

  # Past: The event finished before right now
  scope :past, -> { where("#{sql_ends_at} < ?", Time.current) }

  # Upcoming: The event finishes in the future (includes currently ongoing events)
  scope :upcoming, -> { where("#{sql_ends_at} >= ?", Time.current) }

  # ------------------

  # This is a "virtual attribute" for Ruby logic
  def ends_at
    starts_at + duration_in_minutes.minutes
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[ id name starts_at duration_in_minutes owner ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[ invited_contacts ]
  end

  def invitation_summary
    all_invites = invitations.loaded? ? invitations : invitations.to_a
    {
      total:    all_invites.size,
      attended: all_invites.count { |i| i.attended? }
    }
  end

  private

  def create_invitations_for_contacts
    return unless contact_ids
    clean_ids = contact_ids.reject(&:blank?).map(&:to_i)
    return if clean_ids.empty?

    if persisted?
      existing_ids = invitations.pluck(:contact_id)
      to_remove = existing_ids - clean_ids
      to_add = clean_ids - existing_ids

      invitations.where(contact_id: to_remove).destroy_all if to_remove.any?
      to_add.each { |cid| invitations.create!(contact_id: cid) } if to_add.any?
    else
      clean_ids.each { |cid| invitations.build(contact_id: cid) }
    end
  end
end
