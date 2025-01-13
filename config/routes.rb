Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  resources :journals

  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  get "spotify/search", to: "spotify#search", as: :spotify_search
  get "spotify/results", to: "spotify#results", as: "spotify_results"
  post "spotify/select_tracks", to: "spotify#select_tracks", as: :select_tracks
  get "spotify/autocomplete", to: "spotify#autocomplete"

  # Defines the root path route ("/")
  root "static_pages#top"
end
