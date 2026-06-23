Rails.application.routes.draw do
  # --- System & Engines ---
  mount MissionControl::Jobs::Engine, at: "/jobs"
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # --- Authentication (Auth Zero) ---
  get  "sign_in", to: "sessions#new"
  post "sign_in", to: "sessions#create"
  get  "sign_up", to: "registrations#new"
  post "sign_up", to: "registrations#create"

  resources :sessions, only: [ :index, :show, :destroy ]
  resource  :password, only: [ :edit, :update ]

  namespace :identity do
    resource :email,              only: [ :edit, :update ]
    resource :name,               only: [ :edit, :update ]
    resource :email_verification, only: [ :show, :create ]
    resource :password_reset,     only: [ :new, :edit, :create, :update ]
    resource :time_zone, only: :update
  end

  namespace :authentications do
    resources :user_activities, only: :index
  end

  # Social Login
  get  "/auth/failure",            to: "sessions/omniauth#failure"
  get  "/auth/:provider/callback", to: "sessions/omniauth#create"
  post "/auth/:provider/callback", to: "sessions/omniauth#create"

  # Sudo & Masquerade
  post "users/:user_id/masquerade", to: "masquerades#create", as: :user_masquerade
  namespace :sessions do
    resource :passwordless, only: [ :new, :edit, :create ]
    resource :sudo, only: [ :new, :create ]
  end

  # --- Team & Workspace Management (NEW) ---

  # 1. Accounts (Workspaces) - Switching & CRUD
  resources :accounts, only: [ :new, :create, :edit, :update, :destroy ] do
    member do
      post :switch
    end
  end

  # 2. Settings Routing
  # 'settings' loads the layout, then turbo frames load the specific sections
  get "settings", to: "home#index", as: :settings
  scope :settings do
    get "workspace/general", to: "accounts#edit", as: :edit_workspace
    # Future: get "workspace/billing" ...
  end

  # 3. Team Directory & Membership Management
  resources :members, only: [ :index ]       # The list view
  resources :memberships, only: [ :update, :destroy ] # Role change / Remove / Leave

  # 4. Team Invitations (distinct from Event Invitations)
  resources :team_invitations, only: [ :new, :create, :destroy ] do
    member do
      post :resend
    end
  end

  # 5. Public Acceptance Link (from Email)
  resource :team_invitation_acceptance, only: [ :show, :update ]

  # 6. In-App Notifications
  resources :notifications, only: [ :index, :show ] do
    collection do
      post :mark_all_as_read
    end
  end

  # --- CRM Core (Existing) ---

  resources :contacts do
    collection do
      delete :bulk_destroy
      post :bulk_assign_event
    end
  end

  resources :events do
    # These are EVENT invitations (RSVPs), not Team invitations
    resources :invitations, only: [ :create ], shallow: true
  end

  # Handling updates to Event Invitations (Marking as attended, etc)
  resources :invitations, only: [ :update, :edit, :destroy ] do
    collection do
      patch :bulk_update # NEW
    end
  end

  resources :follow_up_tasks, only: [ :index ] do
    resources :interaction_logs, only: [ :new, :create, :edit, :update, :destroy ], shallow: true do
      member do
        get :confirm_delete
      end
    end

    # Bulk operations
    collection do
      patch :bulk_update
    end
  end

  resources :web_push_subscriptions, only: [ :create ]

  # --- Pages & Dashboard ---
  resource :dashboard, only: [ :show ]

  # Marketing Pages
  get "/pricing", to: "pages#pricing", as: :pricing
  get "/documentation", to: "pages#documentation", as: :documentation
  get "/help", to: "pages#help", as: :help
  get "/privacy", to: "pages#privacy", as: :privacy
  get "/contact-us", to: "pages#contact", as: :contact_us

  root "pages#home"
end
