Rails.application.routes.draw do
  root "user#index"
  get 'user', to: 'user#index'
  get 'monitoring/dashboard', to: 'monitoring#dashboard'
  get 'monitoring', to: 'monitoring#index'
  get 'monitoring/proxy', to: 'monitoring#proxy'
  
  # Cloud Network routes
  get '/cloud_network/show/:id', to: 'cloud_network#show'
  get '/cloud_network/detach/:id', to: 'cloud_network#detach'
  post '/cloud_network/detach_submit/:id', to: 'cloud_network#detach_submit'
  get '/cloud_network/attach/:id', to: 'cloud_network#attach'
  post '/cloud_network/:id', to: 'cloud_network#action'
  
  # API routes
  namespace :api do
    resources :cloud_networks, only: [] do
      member do
        get :available_vms
        get :attached_vms
        post :attach
        post :detach
      end
    end
  end
  
  # Add proxy route with wildcard to capture all paths
  get 'proxy(/*path)', to: 'proxy#index', as: :proxy
  post 'proxy(/*path)', to: 'proxy#index'
  put 'proxy(/*path)', to: 'proxy#index'
  delete 'proxy(/*path)', to: 'proxy#index'
  patch 'proxy(/*path)', to: 'proxy#index'
  # Your other routes
  get 'iframe_test', to: 'application#iframe_test'
  get '/embedded/uptime', to: 'embedded#uptime_kuma'
  get '/embedded/uptime_proxy', to: 'embedded#uptime_proxy'
  get 'uptime', to: 'uptime#index'

  get '/support/zammad_integration', :to => 'support#zammad_integration'
  get 'support/ticket/:id', to: 'support#ticket_details', as: 'support_ticket_details'
  post 'support/ticket/:id/create_note', to: 'support#create_note', as: 'support_create_note'
  post '/tickets/:id/update', to: 'support#update_ticket', as: 'update_ticket'

end
