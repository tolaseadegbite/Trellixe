class TodoContact < ApplicationRecord
  belongs_to :todo
  belongs_to :contact

  validates :contact_id, uniqueness: { scope: :todo_id }
end
