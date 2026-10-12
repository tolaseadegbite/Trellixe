class AccountResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :seat_limit
  attribute :public_id
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :reminder_clock
  attribute :pre_event_enabled
  attribute :pre_event_day_offset
  attribute :pre_event_buffer_minutes
  attribute :post_event_day_offset
  attribute :theme

  # Associations
  attribute :memberships
  attribute :users
  attribute :team_invitations
  attribute :todos
  attribute :contacts
  attribute :events
  attribute :tags
  attribute :event_series
  attribute :invitations
  attribute :follow_up_tasks
  attribute :noticed_events
  attribute :notifications

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
