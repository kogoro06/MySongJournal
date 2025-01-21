Rails.application.routes.draw do
  devise_for :users

  # 管理者用のルートを先に定義
  namespace :admin do
    root to: "dashboard#index"
    resources :admins
    resources :users
    resources :journals
  end

  # 一般ユーザー用のルート
  root "static_pages#top"
  resources :journals
  get "timeline", to: "journals#timeline"

  # その他のルート
  resources :admins
  get "others_journal/index"
  get "up" => "rails/health#show", as: :rails_health_check

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

  resources :users do
    member do
      post "follow"
      delete "unfollow"
    end
  end
end
