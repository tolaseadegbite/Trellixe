class TeamInvitation < ApplicationRecord
  include PublicIdentifiable
  has_public_id prefix: "tinv" # Prefix distinct from your event 'inv' if you have one

  belongs_to :account
  has_secure_token :token

  before_create :set_expiration

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :account_id, message: "has already been invited" }
  validate :email_not_already_member

  def expired?
    expires_at < Time.current
  end

  private

  def set_expiration
    self.expires_at = 48.hours.from_now
  end

  def email_not_already_member
    if account.users.exists?(email: email)
      errors.add(:email, "is already a member of this workspace")
    end
  end
end
