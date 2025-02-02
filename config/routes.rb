Rails.application.routes.draw do
  get "other_users/show"
  get "otherusers/show"
  get "others_journal/index"
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # 日記関連のルート
  resources :journals do
    collection do
      get "timeline", to: "journals#timeline", as: "timeline"
    end
    resource :favorites, only: [ :create, :destroy ]
  end

  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Spotify関連のルート
  get "/spotify/search", to: "spotify#search", as: :spotify_search
  get "/spotify/results", to: "spotify#results", as: "spotify_results"
  post "spotify/select_tracks", to: "spotify#select_tracks", as: :select_tracks
  get "spotify/autocomplete", to: "spotify#autocomplete"

  # 静的ページのルート
  get "/privacy_policy", to: "pages#privacy_policy"
  get "/contact", to: "pages#contact"
  get "/terms", to: "pages#terms"

  # Defines the root path route ("/")
  root "static_pages#top"

  # マイページ関連のルート
  resource :mypage, only: [ :show, :edit, :update ]
  resources :other_users, only: [ :show ]

  resources :users do
    member do
      post "follow", to: "follows#create"
      delete "unfollow", to: "follows#destroy"
      get "following", to: "follows#following"
      get "followers", to: "follows#followers"
    end
  end
end
