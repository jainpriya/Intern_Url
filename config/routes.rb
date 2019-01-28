Rails.application.routes.draw do
  devise_for :users
  resources:urls
  require 'sidekiq/web'
  require 'sidekiq/cron/web'
  mount Sidekiq::Web, :at => '/sidekiq'
  get 'welcome/index'
  get 'users/new'
  root 'welcome#index'
  post 'url_shorteners' => 'urls#create'
  get 'long_url' => 'urls#get_long_url'
  get 'go_to' => 'urls#go_to'
  get 'counter/report'
  get '/search' => 'search#search'
end
