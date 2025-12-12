Rails.application.routes.draw do
  get "ai/chat"
  resources :clients
  resources :calendars do
    collection do
      get :lookup_by_email
      get 'public/:token/availability', to: 'calendars#public_availability', as: :public_availability
      post 'public/:token/events', to: 'calendars#public_create_event', as: :public_create_event
      delete 'public/:token/events/last', to: 'calendars#public_delete_last_event', as: :public_delete_last_event
    end
    get :availability, on: :member
    resources :events, only: [ :index, :create ]
  end
  resources :events, only: [ :show, :update, :destroy ]

  resources :notes do
    collection do
      get :search
    end
  end

  post "ai/chat", to: "ai#chat"

  get "up" => "rails/health#show", as: :rails_health_check
end
