class SolidQueue::JobResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :queue_name
  attribute :class_name
  attribute :arguments
  attribute :priority
  attribute :active_job_id
  attribute :scheduled_at
  attribute :finished_at
  attribute :concurrency_key
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :recurring_execution
  attribute :failed_execution
  attribute :scheduled_execution
  attribute :blocked_execution
  attribute :ready_execution
  attribute :claimed_execution

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
