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

  get 'avis/:id/sign_up/email/:email' => 'backoffice/avis#sign_up', constraints: { email: /.*/ }, as: 'avis_sign_up'
  post 'avis/:id/sign_up/email/:email' => 'backoffice/avis#create_gestionnaire', constraints: { email: /.*/ }

  devise_scope :administrateur do
    get '/administrateurs/sign_in/demo' => 'administrateurs/sessions#demo'
  end

  root 'root#index'

  get 'cgu' => 'cgu#index'
  get 'demo' => 'demo#index'
  get 'users' => 'users#index'
  get 'admin' => 'admin#index'
  get 'backoffice' => 'backoffice#index'

  authenticate :administration do
    resources :administrations, only: [:index, :create]
    namespace :administrations do
      require 'sidekiq/web'
      require 'sidekiq/cron/web'
      mount Sidekiq::Web => '/sidekiq'
    end
  end

  resources :stats, only: [:index]

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
      get '/add_siret' => 'dossiers/add_siret#show'

      get 'description' => 'description#show'
      post 'description' => 'description#update'

      patch 'pieces_justificatives' => 'description#pieces_justificatives'

      get '/recapitulatif' => 'recapitulatif#show'
      post '/recapitulatif/initiate' => 'recapitulatif#initiate'

      post '/commentaire' => 'commentaires#create'
      resources :commentaires, only: [:index]

      get '/carte/position' => 'carte#get_position'
      post '/carte/qp' => 'carte#get_qp'
      post '/carte/cadastre' => 'carte#get_cadastre'

      get '/carte' => 'carte#show'
      post '/carte' => 'carte#save'

      put '/archive' => 'dossiers#archive'

      post '/siret_informations' => 'dossiers#siret_informations'
      put '/change_siret' => 'dossiers#change_siret'

      get 'text_summary' => 'dossiers#text_summary'
    end
    resource :dossiers
  end

  namespace :admin do
    get 'sign_in' => '/administrateurs/sessions#new'
    get 'procedures/archived' => 'procedures#archived'
    get 'procedures/draft' => 'procedures#draft'
    get 'procedures/path_list' => 'procedures#path_list'
    get 'profile' => 'profile#show', as: :profile

    get 'change_dossier_state' => 'change_dossier_state#index'
    post 'change_dossier_state' => 'change_dossier_state#check'
    patch 'change_dossier_state' => 'change_dossier_state#change'

    resources :procedures do
      member do
        post :hide
      end

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

      resources :mail_templates, only: [:index, :edit, :update]

      put 'archive' => 'procedures#archive', as: :archive
      put 'publish' => 'procedures#publish', as: :publish
      post 'transfer' => 'procedures#transfer', as: :transfer
      put 'clone' => 'procedures#clone', as: :clone

      resource :accompagnateurs, only: [:show, :update]

      resource :previsualisation, only: [:show]

      resource :attestation_template, only: [:edit, :update, :create]

      post 'attestation_template/disactivate' => 'attestation_templates#disactivate'
      patch 'attestation_template/disactivate' => 'attestation_templates#disactivate'

      post 'attestation_template/preview' => 'attestation_templates#preview'
      patch 'attestation_template/preview' => 'attestation_templates#preview'
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

    get 'invitations'

    resources :dossiers do
      post 'receive' => 'dossiers#receive'
      post 'process_dossier' => 'dossiers#process_dossier'
      member do
        post 'archive'
        post 'unarchive'
      end
      post 'reopen' => 'dossiers#reopen'
      resources :commentaires, only: [:index]
      resources :avis, only: [:create, :update]
    end

    namespace :dossiers do
      post 'filter'

      get 'procedure/:id' => 'procedure#index', as: 'procedure'
      post 'procedure/:id/filter' => 'procedure#filter', as: 'procedure_filter'
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

  get "patron" => "root#patron"

  scope module: 'new_user' do
    resources :dossiers, only: [] do
      get 'attestation'
    end
  end

  scope module: 'new_gestionnaire' do
    resources :procedures, only: [:index, :show], param: :procedure_id do
      member do
        resources :dossiers, only: [:show], param: :dossier_id do
          member do
            get 'attestation'
            get 'messagerie'
            get 'annotations-privees' => 'dossiers#annotations_privees'
            get 'avis'
            patch 'follow'
            patch 'unfollow'
            patch 'archive'
            patch 'unarchive'
            patch 'annotations' => 'dossiers#update_annotations'
            post 'commentaire' => 'dossiers#create_commentaire'
            scope :carte do
              get 'position'
            end
            post 'avis' => 'dossiers#create_avis'
          end
        end
      end
    end
    resources :avis, only: [:index, :show, :update] do
      member do
        get 'instruction'
        get 'messagerie'
        post 'commentaire' => 'avis#create_commentaire'
        post 'avis' => 'avis#create_avis'
      end
    end
    get "recherche" => "recherches#index"
  end

  apipie
end
