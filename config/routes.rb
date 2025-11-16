Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  root "pages#home"
  get  "sign_in", to: "sessions#new"
  post "sign_in", to: "sessions#create"
  get  "sign_up", to: "registrations#new"
  post "sign_up", to: "registrations#create"
  resources :sessions, only: [ :index, :show, :destroy ]
  resource  :password, only: [ :edit, :update ]
  namespace :identity do
    resource :email,              only: [ :edit, :update ]
    resource :email_verification, only: [ :show, :create ]
    resource :password_reset,     only: [ :new, :edit, :create, :update ]
  end
  namespace :authentications do
    resources :user_activities, only: :index
  end
  get  "/auth/failure",            to: "sessions/omniauth#failure"
  get  "/auth/:provider/callback", to: "sessions/omniauth#create"
  post "/auth/:provider/callback", to: "sessions/omniauth#create"
  post "users/:user_id/masquerade", to: "masquerades#create", as: :user_masquerade
  # resource :invitation, only: [:new, :create]
  namespace :sessions do
    resource :passwordless, only: [ :new, :edit, :create ]
    resource :sudo, only: [ :new, :create ]
  end

  resources :contacts
  resources :events do
    resources :invitations, only: [ :create ], shallow: true
  end
  resources :invitations, only: [ :update, :edit, :destroy ]

   resources :follow_up_tasks, only: [ :index ] do
    resources :interaction_logs, only: [ :new, :create ], shallow: true
  end

  resources :web_push_subscriptions, only: [ :create ]

  resource :dashboard, only: [ :show ]

  get "/home", to: "pages#home", as: :home
  get "/pricing", to: "pages#pricing", as: :pricing
  get "/documentation", to: "pages#documentation", as: :documentation
  get "/help", to: "pages#help", as: :help
  get "/privacy", to: "pages#privacy", as: :privacy
  get "/contact-us", to: "pages#contact", as: :contact_us
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
end
