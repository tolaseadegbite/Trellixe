class Contact < ApplicationRecord
  validates :first_name, presence: true

  belongs_to :owner, polymorphic: true
  belongs_to :creator, class_name: "User"

  has_many :invitations, dependent: :destroy
  has_many :interaction_logs, dependent: :destroy
  has_many :events, through: :invitations
  has_many :contact_tags, dependent: :destroy
  has_many :tags, through: :contact_tags

  # 1. Ransack Alias: Maps 'combined_search' to multiple columns
  # URL becomes: ?q[combined_search_cont]=David
  ransack_alias :combined_search, :first_name_or_last_name_or_email_or_phone_number_or_how_we_met

  # 2. Allow searching into associations (for Status filtering)
  def self.ransackable_attributes(auth_object = nil)
    %w[ id first_name last_name email phone_number how_we_met created_at updated_at combined_search ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[ events invitations tags ]
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
