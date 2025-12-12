Rails.application.routes.draw do
  get "ai/chat"
  resources :clients
  resources :calendars do
    collection do
      get :lookup_by_email
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
