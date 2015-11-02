Rails.application.routes.draw do

  devise_for :administrateurs, controllers: {
                                 sessions: 'administrateurs/sessions'
                             }, skip: [:password, :registrations]

  devise_for :gestionnaires, controllers: {
                               sessions: 'gestionnaires/sessions'
                           }, skip: [:password, :registrations]

  devise_for :users, controllers: {
                       sessions: 'users/sessions'
                   }

  #root 'users/dossiers#index'
  root 'root#index'

  get 'france_connect' => 'france_connect#login'
  get 'france_connect/callback' => 'france_connect#callback'

  namespace :users do
    get 'siret' => 'siret#index'

    resources :dossiers do
      get '/description' => 'description#show'
      get '/description/error' => 'description#error'
      post 'description' => 'description#create'
      get '/recapitulatif' => 'recapitulatif#show'
      post '/recapitulatif/submit' => 'recapitulatif#submit'
      post '/recapitulatif/submit_validate' => 'recapitulatif#submit_validate'
      # get '/demande' => 'demandes#show'
      # post '/demande' => 'demandes#update'
      post '/commentaire' => 'commentaires#create'

      get '/carte/position' => 'carte#get_position'
      get '/carte' => 'carte#show'
      post '/carte' => 'carte#save_ref_api_carto'

    end
    resource :dossiers
  end

  get 'admin' => 'admin#index'

  namespace :admin do
    get 'sign_in' => '/administrateurs/sessions#new'
    resources :procedures do

    end
  end

  get 'backoffice' => 'backoffice#index'

  namespace :backoffice do
    get 'sign_in' => '/gestionnaires/sessions#new'

    resources :dossiers do
      post 'valid' => 'dossiers#valid'
      post 'process' => 'dossiers#process_end'
    end
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
