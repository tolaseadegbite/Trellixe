class UserResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :email
  attribute :verified
  attribute :provider
  attribute :uid
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :name
  attribute :public_id
  attribute :time_zone
  attribute :terms_accepted_at
  attribute :password, index: false, show: false
  attribute :password_confirmation, index: false, show: false
  attribute :avatar, index: false

  # Associations
  attribute :memberships
  attribute :accounts
  attribute :follow_up_tasks
  attribute :todos
  attribute :created_todos
  attribute :todo_participations
  attribute :pre_event_digests
  attribute :sessions
  attribute :sign_in_tokens
  attribute :user_activities
  attribute :web_push_subscriptions
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
