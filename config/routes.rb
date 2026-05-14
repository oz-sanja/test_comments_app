Rails.application.routes.draw do
  devise_for :users

  root "comments#index"

  resources :comments do
    collection do
      get :search
    end
  end

  resources :notifications, only: [:index] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_as_read
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
