class ContactTag < ApplicationRecord
  belongs_to :contact
  belongs_to :tag
end
