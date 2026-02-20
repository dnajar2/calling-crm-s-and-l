Rails.application.routes.draw do
  # Authentication routes
  namespace :auth do
    post :register
    post :login
    post :logout
    post :refresh
    post :forgot_password
    post :reset_password
    get :me
    patch :update
    get :timezones
  end

  # OAuth routes
  get "/auth/:provider/callback", to: "oauth#callback"
  get "/auth/failure", to: "oauth#failure"

  # API routes (protected by authentication)
  get "ai/chat"
  resources :clients do
    collection do
      get :recent
    end
  end
  resources :calendars do
    collection do
      get :primary
      get 'public/:token/availability', to: 'calendars#public_availability', as: :public_availability
      post 'public/:token/events', to: 'calendars#public_create_event', as: :public_create_event
      delete 'public/:token/events/last', to: 'calendars#public_delete_last_event', as: :public_delete_last_event
    end
    member do
      get :availability
      get :token_stats
      post :regenerate_token
      post :revoke_token
      post :extend_token
    end
    resources :events, only: [ :index, :create ]
    resources :blockouts, controller: 'calendar_blockouts'
  end
  resources :events, only: [ :show, :update, :destroy ] do
    collection do
      get :dashboard
      get :today
      get :upcoming
    end
    resources :event_notes
  end

  resources :notes do
    collection do
      get :search
    end
  end

  post "ai/chat", to: "ai#chat"

  get "up" => "rails/health#show", as: :rails_health_check
end
