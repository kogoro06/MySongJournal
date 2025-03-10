Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    passwords: "users/passwords"
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

  # OGP画像のルーティング
  get "images/ogp", to: "images#ogp", format: :png

  # お問い合わせフォーム
  resources :contacts, only: [ :new, :create ]
  get "/contact", to: "contacts#new"

  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Spotify関連のルート
  get "/spotify/search", to: "spotify#search", as: :spotify_search
  get "/spotify/results", to: "spotify#results", as: "spotify_results"
  post "spotify/select_tracks", to: "spotify#select_tracks", as: :select_tracks
  get "spotify/autocomplete", to: "spotify#autocomplete"
  get "spotify/artist_genres", to: "spotify#artist_genres"

  # 静的ページのルート
  get "/privacy_policy", to: "pages#privacy_policy"
  get "/terms", to: "pages#terms"
  get "static_pages/app_explanation", to: "static_pages#app_explanation", as: "app_explanation"

  # Defines the root path route ("/")
  root "static_pages#top"

  # マイページ関連のルート
  resource :mypage, only: [ :show, :edit, :update ]
  resources :other_users, only: [ :show ] do
    member do
      get "x_redirect"
    end
  end

  resources :users do
    member do
      post "follow", to: "follows#create"
      delete "unfollow", to: "follows#destroy"
      get "following", to: "follows#following"
      get "followers", to: "follows#followers"
      get "x_redirect", to: "users#x_redirect"
    end
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
