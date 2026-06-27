class Tag < ApplicationRecord
  validates :name, presence: true, uniqueness: { scope: [ :owner_type, :owner_id ] }

  belongs_to :owner, polymorphic: true

  has_many :contact_tags, dependent: :destroy
  has_many :contacts, through: :contact_tags
  has_many :tagged_event_series, dependent: :destroy
  has_many :event_series, through: :tagged_event_series
end
