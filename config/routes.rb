Rails.application.routes.draw do
  get "feeds/rss"
  get "posts/index"
  get "posts/show"
  get "pages/home"
  get "pages/about"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"

  get "about" => "pages#about"

  get "blog(/:page)", to: "posts#index", as: :blog_index, page: /\d+/
  get "musings(/:page)", to: "musings#index", as: :musings_index, page: /\d+/

  get "musings/:year/:month/:slug" => "musings#show", constraints: {
    year: /\d{4}/, # Ensure year is 4 digits
    month: /\d{2}/ # Ensure month is 2 digits
  }, as: :musing

  get "posts/:year/:month/:slug" => "posts#show", constraints: {
    year: /\d{4}/, # Ensure year is 4 digits
    month: /\d{2}/ # Ensure month is 2 digits
  }, as: :post

  get "/feed", to: "feeds#rss", defaults: { format: "xml" }, as: :rss_feed

  match "/404", to: "errors#not_found", via: :all
  match "*unmatched", to: "errors#not_found", via: :all
end
