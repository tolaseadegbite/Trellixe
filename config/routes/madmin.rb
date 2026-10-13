# Below are the routes for madmin
namespace :madmin do
  resources :todo_contacts
  resources :todo_participations
  resources :users
  resources :tagged_event_series
  resources :team_invitations
  resources :todos
  resources :sessions
  resources :sign_in_tokens
  resources :tags
  resources :invitations
  resources :memberships
  resources :pre_event_digests
  resources :follow_up_tasks
  resources :interaction_logs
  resources :contact_tags
  resources :event_series
  resources :contacts
  resources :accounts
  namespace :team_notifier do
    namespace :invitation_declined do
      resources :notifications
    end
  end
  namespace :team_notifier do
    resources :invitation_receiveds
  end
  namespace :team_notifier do
    namespace :invitation_received do
      resources :notifications
    end
  end
  namespace :team_notifier do
    resources :member_joineds
  end
  namespace :team_notifier do
    namespace :member_joined do
      resources :notifications
    end
  end
  namespace :team_notifier do
    resources :member_lefts
  end
  namespace :team_notifier do
    namespace :member_left do
      resources :notifications
    end
  end
  namespace :team_notifier do
    resources :member_removeds
  end
  namespace :team_notifier do
    namespace :member_removed do
      resources :notifications
    end
  end
  namespace :team_notifier do
    resources :role_changeds
  end
  namespace :team_notifier do
    namespace :role_changed do
      resources :notifications
    end
  end
  resources :application_notifiers
  namespace :application_notifier do
    resources :notifications
  end
  resources :follow_up_task_notifiers
  namespace :follow_up_task_notifier do
    resources :notifications
  end
  resources :pre_event_digest_notifiers
  namespace :pre_event_digest_notifier do
    resources :notifications
  end
  resources :team_notifiers
  namespace :team_notifier do
    resources :notifications
  end
  namespace :team_notifier do
    resources :invitation_declineds
  end
  namespace :active_storage do
    resources :attachments
  end
  namespace :active_storage do
    resources :blobs
  end
  namespace :active_storage do
    resources :variant_records
  end
  resources :user_activities
  resources :web_push_subscriptions
  namespace :noticed do
    resources :events
  end
  namespace :noticed do
    resources :notifications
  end
  resources :events
  root to: "dashboard#show"
end
