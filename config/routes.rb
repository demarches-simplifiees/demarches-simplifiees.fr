Rails.application.routes.draw do

  get "/ping" => "ping#index", :constraints => {:ip => /127.0.0.1/}

  devise_for :administrations, skip: [:password, :registrations]

  devise_for :administrateurs, controllers: {
                                 sessions: 'administrateurs/sessions'
                             }, skip: [:password, :registrations]

  devise_for :gestionnaires, controllers: {
                               sessions: 'gestionnaires/sessions',
                               passwords: 'gestionnaires/passwords'
                           }, skip: [:registrations]

  devise_for :users, controllers: {
                       sessions: 'users/sessions',
                       registrations: 'users/registrations',
                       passwords: 'users/passwords'
                   }

  devise_scope :user do
    get '/users/sign_in/demo' => 'users/sessions#demo'
    get '/users/no_procedure' => 'users/sessions#no_procedure'
  end

  devise_scope :gestionnaire do
    get '/gestionnaires/sign_in/demo' => 'gestionnaires/sessions#demo'
    get '/gestionnaires/edit' => 'gestionnaires/registrations#edit', :as => 'edit_gestionnaires_registration'
    put '/gestionnaires' => 'gestionnaires/registrations#update', :as => 'gestionnaires_registration'
  end

  devise_scope :administrateur do
    get '/administrateurs/sign_in/demo' => 'administrateurs/sessions#demo'
  end

  root 'root#index'

  namespace :france_connect do
    get 'particulier' => 'particulier#login'
    get 'particulier/callback' => 'particulier#callback'

    get 'particulier/new' => 'particulier#new'
    post 'particulier/create' => 'particulier#create'
    post 'particulier/check_email' => 'particulier#check_email'
  end

  get 'demo' => 'demo#index'
  get 'users' => 'users#index'

  namespace :users do
    namespace :dossiers do
      resources :invites, only: [:index, :show]

      post '/commentaire' => 'commentaires#create'
    end

    resources :dossiers do
      get '/description' => 'description#show'
      get '/description/error' => 'description#error'
      post 'description' => 'description#create'

      patch 'pieces_justificatives' => 'description#pieces_justificatives'

      get '/recapitulatif' => 'recapitulatif#show'
      post '/recapitulatif/initiate' => 'recapitulatif#initiate'
      post '/recapitulatif/submit' => 'recapitulatif#submit'

      post '/commentaire' => 'commentaires#create'

      get '/carte/position' => 'carte#get_position'
      post '/carte/qp' => 'carte#get_qp'
      post '/carte/cadastre' => 'carte#get_cadastre'

      get '/carte' => 'carte#show'
      post '/carte' => 'carte#save'

      put '/archive' => 'dossiers#archive'

      post '/siret_informations' => 'dossiers#siret_informations'
      put '/change_siret' => 'dossiers#change_siret'
    end
    resource :dossiers
  end

  get 'admin' => 'admin#index'

  namespace :admin do
    get 'sign_in' => '/administrateurs/sessions#new'
    get 'procedures/archived' => 'procedures#archived'
    get 'procedures/draft' => 'procedures#draft'
    get 'profile' => 'profile#show', as: :profile

    resources :procedures do
      resource :types_de_champ, only: [:show, :update] do
        post '/:index/move_up' => 'types_de_champ#move_up', as: :move_up
        post '/:index/move_down' => 'types_de_champ#move_down', as: :move_down
      end
      resource :pieces_justificatives, only: [:show, :update] do
        post '/:index/move_up' => 'pieces_justificatives#move_up', as: :move_up
        post '/:index/move_down' => 'pieces_justificatives#move_down', as: :move_down
      end

      put 'archive' => 'procedures#archive', as: :archive
      put 'publish' => 'procedures#publish', as: :publish
      put 'clone' => 'procedures#clone', as: :clone

      resource :accompagnateurs, only: [:show, :update]

      resource :previsualisation, only: [:show]

      resources :types_de_champ, only: [:destroy]
      resource :pieces_justificatives, only: [:show, :update]
      resources :pieces_justificatives, only: :destroy
    end

    namespace :accompagnateurs do
      get 'show' #delete after fixed tests admin/accompagnateurs/show_spec without this line
    end

    resources :gestionnaires, only: [:index, :create, :destroy]
  end

  namespace :ban do
    get 'search' => 'search#get'
    get 'address_point' => 'search#get_address_point'
  end

  get 'backoffice' => 'backoffice#index'

  namespace :backoffice do
    get 'sign_in' => '/gestionnaires/sessions#new'

    get 'dossiers/search' => 'dossiers#search'

    get 'filtres' => 'procedure_filter#index'
    patch 'filtres/update' => 'procedure_filter#update'


    resources :dossiers do
      post 'valid' => 'dossiers#valid'
      post 'close' => 'dossiers#close'

      post 'invites' => '/invites#create'
    end

    resources :commentaires, only: [:create]
  end

  resources :administrations

  namespace :api do
    namespace :v1 do
      resources :procedures, only: [:index, :show] do
        resources :dossiers, only: [:index, :show]
      end
    end

    namespace :statistiques do
      get 'dossiers' => '/api/statistiques#dossiers_stats'
    end
  end

  apipie
end
