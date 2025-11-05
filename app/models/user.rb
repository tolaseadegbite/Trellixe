class User < ApplicationRecord
  has_secure_password

  generates_token_for :email_verification, expires_in: 2.days do
    email
  end

  generates_token_for :password_reset, expires_in: 20.minutes do
    password_salt.last(10)
  end


  belongs_to :account

  has_many :sessions, dependent: :destroy
  has_many :sign_in_tokens, dependent: :destroy
  has_many :user_activities, dependent: :destroy

  has_many :contacts, as: :owner, dependent: :destroy
  has_many :created_contacts, class_name: "Contact", foreign_key: "creator_id", dependent: :destroy

  has_many :events, as: :owner, dependent: :destroy
  has_many :follow_up_tasks, dependent: :destroy
  has_many :interaction_logs, dependent: :destroy

  has_many :web_push_subscriptions

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_nil: true, length: { minimum: 12 }
  validates :password, not_pwned: { message: "might easily be guessed" }

  normalizes :email, with: -> { _1.strip.downcase }

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  before_validation on: :create do
    self.account = Account.new
  end

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: Current.session).delete_all
  end

  after_update if: :email_previously_changed? do
    user_activities.create! action: "email_verification_requested"
  end

  after_update if: :password_digest_previously_changed? do
    user_activities.create! action: "password_changed"
  end

  after_update if: [ :verified_previously_changed?, :verified? ] do
    user_activities.create! action: "email_verified"
  end
end
