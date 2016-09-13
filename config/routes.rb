Rails.application.routes.draw do
  default_url_options protocol: :https

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

  get 'cgu' => 'cgu#index'
  get 'demo' => 'demo#index'
  get 'users' => 'users#index'
  get 'admin' => 'admin#index'
  get 'backoffice' => 'backoffice#index'

  resources :administrations

  namespace :france_connect do
    get 'particulier' => 'particulier#login'
    get 'particulier/callback' => 'particulier#callback'

    get 'particulier/new' => 'particulier#new'
    post 'particulier/create' => 'particulier#create'
    post 'particulier/check_email' => 'particulier#check_email'
  end

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

  namespace :admin do
    get 'sign_in' => '/administrateurs/sessions#new'
    get 'procedures/archived' => 'procedures#archived'
    get 'procedures/draft' => 'procedures#draft'
    get 'procedures/path_list' => 'procedures#path_list'
    get 'profile' => 'profile#show', as: :profile

    resources :procedures do
      resources :types_de_champ, only: [:destroy]
      resource :types_de_champ, only: [:show, :update] do
        post '/:index/move_up' => 'types_de_champ#move_up', as: :move_up
        post '/:index/move_down' => 'types_de_champ#move_down', as: :move_down
      end

      resources :types_de_champ_private, only: [:destroy]
      resource :types_de_champ_private, only: [:show, :update] do
        post '/:index/move_up' => 'types_de_champ_private#move_up', as: :move_up
        post '/:index/move_down' => 'types_de_champ_private#move_down', as: :move_down
      end

      resource :pieces_justificatives, only: [:show, :update]
      resources :pieces_justificatives, only: :destroy
      resource :pieces_justificatives, only: [:show, :update] do
        post '/:index/move_up' => 'pieces_justificatives#move_up', as: :move_up
        post '/:index/move_down' => 'pieces_justificatives#move_down', as: :move_down
      end

      resources 'mails'

      put 'archive' => 'procedures#archive', as: :archive
      put 'publish' => 'procedures#publish', as: :publish
      post 'transfer' => 'procedures#transfer', as: :transfer
      put 'clone' => 'procedures#clone', as: :clone

      resource :accompagnateurs, only: [:show, :update]

      resource :previsualisation, only: [:show]

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

  namespace :invites do
    post 'dossier/:dossier_id' => '/invites#create', as: 'dossier'
  end

  namespace :backoffice do
    get 'sign_in' => '/gestionnaires/sessions#new'
    get 'dossiers/search' => 'dossiers#search'
    get 'download_dossiers_tps' => 'dossiers#download_dossiers_tps'

    resource :private_formulaire

    resources :dossiers do
      post 'valid' => 'dossiers#valid'
      post 'receive' => 'dossiers#receive'
      post 'refuse' => 'dossiers#refuse'
      post 'without_continuation' => 'dossiers#without_continuation'
      post 'close' => 'dossiers#close'

      put 'follow' => 'dossiers#follow'
    end

    namespace :dossiers do
      resources :procedure, only: [:show]
    end

    resources :commentaires, only: [:create]

    namespace :preference_list_dossier do
      post 'add'
      delete 'delete'

      get 'reload_smartlisting' => '/backoffice/dossiers#reload_smartlisting'
      get 'reload_pref_list'
    end
  end

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

  namespace :commencer do
    get '/:procedure_path' => '/users/dossiers#commencer'
  end

  apipie
end
