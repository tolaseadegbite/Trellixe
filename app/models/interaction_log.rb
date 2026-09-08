class InteractionLog < ApplicationRecord
  validates :note, presence: true
  belongs_to :contact
  belongs_to :user
  belongs_to :follow_up_task, optional: true
  belongs_to :event, optional: true
end
