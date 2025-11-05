class Contact < ApplicationRecord
  # == Validations =================
  validates :first_name, presence: true

  # == Associations ===============
  belongs_to :owner, polymorphic: true
  belongs_to :creator, class_name: "User"

  # --- ADD THESE TWO LINES ---
  has_many :invitations, dependent: :destroy
  has_many :interaction_logs, dependent: :destroy
  # -------------------------

  # This is a useful helper association to get directly to the events.
  has_many :events, through: :invitations

  # == Methods =====================
  def self.ransackable_attributes(auth_object = nil)
    %w[ id first_name last_name email phone_number how_we_met created_at updated_at ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[ events ]
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
