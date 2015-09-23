Rails.application.routes.draw do

  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  devise_for :gestionnaires, controllers: {
    sessions: 'gestionnaires/sessions'
  }, skip: [:password, :registrations]


  # root 'welcome#index'
  root 'users/dossiers#index'

  get 'siret' => 'siret#index'
  # get 'start/index'
  # get 'start/error_siret'
  # get 'start/error_login'
  # get 'start/error_dossier'

  resources :dossiers do
    get '/demande' => 'demandes#show'
    post '/demande' => 'demandes#update'

    get '/carte/position' => 'carte#get_position'
    get '/carte' => 'carte#show'
    post '/carte' => 'carte#save_ref_api_carto'

    get '/description' => 'description#show'
    get '/description/error' => 'description#error'
    post 'description' => 'description#create'

    get '/recapitulatif' => 'recapitulatif#show'

    post '/commentaire' => 'commentaires#create'
  end


  get 'backoffice' => 'backoffice#index'

namespace :backoffice do
  get 'sign_in' => '/gestionnaires/sessions#new'
  resources :dossiers, only: [:show]
  resources :commentaires, only: [:create]
end
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
