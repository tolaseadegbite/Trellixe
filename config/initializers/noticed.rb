Rails.application.config.to_prepare do
  Noticed::Notification.class_eval do
    belongs_to :account, optional: true
    belongs_to :recipient, polymorphic: true
  end
end
