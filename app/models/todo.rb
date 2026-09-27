class Todo < ApplicationRecord
  validates :title, presence: true
  validates :progress_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :target_count, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validate :progress_within_target
  validate :assignee_in_account
  validate :personal_owned_by_creator

  belongs_to :account
  # Nil assignee = the whole team (shared todos only; personal todos must
  # belong to their creator — enforced by personal_owned_by_creator).
  belongs_to :user, optional: true
  belongs_to :creator, class_name: "User"

  has_many :todo_contacts, dependent: :destroy
  has_many :contacts, through: :todo_contacts
  has_many :todo_participations, dependent: :destroy
  has_many :participants, through: :todo_participations, source: :user

  enum :visibility, { shared: "shared", personal: "personal" }, default: :shared

  scope :open, -> { where(completed_at: nil) }
  scope :done, -> { where.not(completed_at: nil) }
  scope :goals, -> { where.not(target_count: nil) }
  # Privacy boundary: shared todos are visible to every member, personal
  # todos only to their creator — enforced in the query, not the view.
  scope :visible_to, ->(user) { where(visibility: :shared).or(where(user: user)) }
  # A member owes their assigned todos plus unassigned (team-wide) ones.
  # Personal todos always have an assignee, so the nil branch only ever
  # matches shared work.
  scope :for_member, ->(user) { where(user: user).or(where(user_id: nil)) }

  attr_accessor :contact_ids

  after_create :sync_contacts
  after_update :sync_contacts

  def self.ransackable_attributes(auth_object = nil)
    %w[ id title due_at completed_at visibility user_id created_at updated_at ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[ contacts user ]
  end

  def completed? = completed_at.present?

  def goal? = target_count.present?

  def overdue? = !completed? && due_at.present? && due_at < Time.current

  def participated?(user) = todo_participations.exists?(user: user)

  private

  def progress_within_target
    return unless target_count.present? && progress_count > target_count

    errors.add(:progress_count, "can't exceed the target")
  end

  def assignee_in_account
    return unless account && user && !account.users.exists?(user.id)

    errors.add(:user, "must be a workspace member")
  end

  def personal_owned_by_creator
    return unless personal? && creator && user != creator

    errors.add(:user, "personal todos belong to their creator")
  end

  # Mirrors Event#create_invitations_for_contacts: diff the submitted ids
  # against existing rows so edits replace the set without duplicates.
  def sync_contacts
    return unless contact_ids

    clean_ids = account.contacts.where(id: contact_ids.reject(&:blank?).map(&:to_i)).pluck(:id)

    existing_ids = todo_contacts.pluck(:contact_id)
    to_remove = existing_ids - clean_ids
    to_add = clean_ids - existing_ids

    todo_contacts.where(contact_id: to_remove).destroy_all if to_remove.any?
    to_add.each { |cid| todo_contacts.create!(contact_id: cid) } if to_add.any?
  end
end
