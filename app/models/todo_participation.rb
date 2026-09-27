class TodoParticipation < ApplicationRecord
  belongs_to :todo
  belongs_to :user

  validates :user_id, uniqueness: { scope: :todo_id }
end
