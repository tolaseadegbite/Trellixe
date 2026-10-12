class TodoResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :title
  attribute :due_at
  attribute :completed_at
  attribute :visibility
  attribute :target_count, form: false
  attribute :progress_count, form: false
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :account
  attribute :user
  attribute :creator
  attribute :todo_contacts
  attribute :contacts
  attribute :todo_participations
  attribute :participants

  # Add scopes to easily filter records
  # scope :published

  # Add actions to the resource's show page
  # Pass collection: true to also render it in each row on the index page
  # member_action do |record|
  #   link_to "Do Something", some_path
  # end

  # Add actions to the resource's index page
  # collection_action do
  #   link_to "Bulk Import", bulk_import_path, class: "btn btn-secondary"
  # end

  # Customize the display name of records in the admin area.
  # def self.display_name(record) = record.name

  # Customize the default sort column and direction.
  # def self.default_sort_column = "created_at"
  #
  # def self.default_sort_direction = "desc"
end
