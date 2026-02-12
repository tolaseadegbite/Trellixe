class User < ApplicationRecord
  include PublicIdentifiable
  has_public_id prefix: "user"

  has_secure_password

  # Multitenancy (Replaces 'belongs_to :account')
  has_many :memberships, dependent: :destroy
  has_many :accounts, through: :memberships
  has_many :follow_up_tasks, dependent: :destroy

  # Authentication tokens
  generates_token_for :email_verification, expires_in: 2.days do
    email
  end

  generates_token_for :password_reset, expires_in: 20.minutes do
    password_salt.last(10)
  end

  # Trellixe Specific Associations
  has_many :sessions, dependent: :destroy
  has_many :sign_in_tokens, dependent: :destroy
  has_many :user_activities, dependent: :destroy
  has_many :web_push_subscriptions, dependent: :destroy

  # Notifications
  has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_nil: true, length: { minimum: 12 }
  validates :password, not_pwned: { message: "might easily be guessed" }

  normalizes :email, with: -> { _1.strip.downcase }

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  # Onboarding: Auto-create workspace
  after_create :create_personal_workspace

  def full_name
    # Assuming you might add first/last name columns later, or derived from email for now
    name || email.split("@").first.humanize
  end

  def initials
    # Simple fallback if name is just one word or nil
    (name || email).first.upcase
  end

  private

  def create_personal_workspace
    # Only create if they didn't join via an invitation
    return if memberships.any?

    transaction do
      # e.g. "David's Workspace"
      workspace_name = name.present? ? "#{name.split.first}'s Workspace" : "Personal Workspace"

      personal_account = Account.create!(name: workspace_name)
      memberships.create!(account: personal_account, role: "admin")
    end
  end
end
