class Membership < ApplicationRecord
  include PublicIdentifiable
  has_public_id prefix: "mem"

  belongs_to :user
  belongs_to :account

  enum :role, { member: "member", admin: "admin" }, default: :member

  validates :user_id, uniqueness: { scope: :account_id }
end
