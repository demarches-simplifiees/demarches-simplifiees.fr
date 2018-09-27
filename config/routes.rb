Rails.application.routes.draw do
  #
  # Manager
  #

  get 'manager/sign_in' => 'administrations/sessions#new'
  delete 'manager/sign_out' => 'administrations/sessions#destroy'
  namespace :manager do
    resources :procedures, only: [:index, :show] do
      post 'whitelist', on: :member
    end

    resources :dossiers, only: [:index, :show] do
      post 'change_state_to_instruction', on: :member
    end

    resources :administrateurs, only: [:index, :show, :new, :create] do
      post 'reinvite', on: :member
      put 'enable_feature', on: :member
    end

    resources :users, only: [:index, :show] do
      post 'resend_confirmation_instructions', on: :member
      post 'confirm', on: :member
    end

    resources :gestionnaires, only: [:index, :show] do
      post 'reinvite', on: :member
    end

    resources :dossiers, only: [:show]

    resources :demandes, only: [:index]
    post 'demandes/create_administrateur'
    post 'demandes/refuse_administrateur'

    authenticate :administration do
      mount Flipflop::Engine => "/features"
      match "/delayed_job" => DelayedJobWeb, :anchor => false, :via => [:get, :post]
    end

    root to: "administrateurs#index"
  end

  #
  # Monitoring
  #

  get "/ping" => "ping#index", :constraints => { :ip => /127.0.0.1/ }

  #
  # Authentication
  #

  devise_for :administrations,
    skip: [:password, :registrations, :sessions],
    controllers: {
      omniauth_callbacks: 'administrations/omniauth_callbacks'
    }

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
    get '/users/sign_in/demo' => redirect("/users/sign_in")
    get '/users/no_procedure' => 'users/sessions#no_procedure'
  end

  devise_scope :gestionnaire do
    get '/gestionnaires/sign_in/demo' => redirect("/users/sign_in")
    get '/gestionnaires/edit' => 'gestionnaires/registrations#edit', :as => 'edit_gestionnaires_registration'
    put '/gestionnaires' => 'gestionnaires/registrations#update', :as => 'gestionnaires_registration'
  end

  devise_scope :administrateur do
    get '/administrateurs/sign_in/demo' => redirect("/users/sign_in")
  end

  #
  # Main routes
  #

  root 'root#index'
  get '/tour-de-france' => 'tour_de_france#index'
  get '/administration' => 'root#administration'

  get 'users' => 'users#index'
  get 'admin' => 'admin#index'

  get '/stats' => 'stats#index'
  get '/stats/download' => 'stats#download'
  resources :accessibilite, only: [:index]
  resources :demandes, only: [:new, :create]

  namespace :france_connect do
    get 'particulier' => 'particulier#login'
    get 'particulier/callback' => 'particulier#callback'
  end

  namespace :champs do
    get ':position/siret', to: 'siret#show', as: :siret
    get ':position/dossier_link', to: 'dossier_link#show', as: :dossier_link
  end

  namespace :commencer do
    get '/test/:procedure_path' => '/users/dossiers#commencer_test', as: :test
    get '/:procedure_path' => '/users/dossiers#commencer'
  end

  get "patron" => "root#patron"

  get "contact", to: "support#index"
  post "contact", to: "support#create"

  post "webhooks/helpscout", to: "webhook#helpscout"
  match "webhooks/helpscout", to: lambda { |_| [204, {}, nil] }, via: :head

  #
  # Deprecated UI
  #

  namespace :users do
    namespace :dossiers do
      resources :invites, only: [:index, :show]

      post '/commentaire' => 'commentaires#create'
    end

    resources :dossiers do
      get '/add_siret' => 'dossiers/add_siret#show'

      patch 'pieces_justificatives' => 'description#pieces_justificatives'

      # TODO: once these pages will be migrated to the new user design, replace these routes by a redirection
      get '/recapitulatif' => 'recapitulatif#show'
      post '/recapitulatif/initiate' => 'recapitulatif#initiate'
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

    resource 'dossiers'

    # Redirection of legacy "/users/dossiers" route to "/dossiers"
    get 'dossiers', to: redirect('/dossiers')
  end

  namespace :gestionnaire do
    get 'activate' => '/gestionnaires/activate#new'
    patch 'activate' => '/gestionnaires/activate#create'
  end

  namespace :admin do
    get 'activate' => '/administrateurs/activate#new'
    patch 'activate' => '/administrateurs/activate#create'
    get 'activate/test_password_strength' => '/administrateurs/activate#test_password_strength'
    get 'sign_in' => '/administrateurs/sessions#new'
    get 'procedures/archived' => 'procedures#archived'
    get 'procedures/draft' => 'procedures#draft'
    get 'procedures/path_list' => 'procedures#path_list'
    get 'procedures/available' => 'procedures#check_availability'

    get 'change_dossier_state' => 'change_dossier_state#index'
    post 'change_dossier_state' => 'change_dossier_state#check'
    patch 'change_dossier_state' => 'change_dossier_state#change'

    resources :procedures do
      collection do
        get 'new_from_existing' => 'procedures#new_from_existing', as: :new_from_existing
      end

      member do
        post :hide
        delete :delete_logo
        delete :delete_deliberation
        delete :delete_notice
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

      resource :instructeurs, only: [:show, :update]

      resource :attestation_template, only: [:edit, :update, :create]

      post 'attestation_template/disactivate' => 'attestation_templates#disactivate'
      patch 'attestation_template/disactivate' => 'attestation_templates#disactivate'

      post 'attestation_template/preview' => 'attestation_templates#preview'
      patch 'attestation_template/preview' => 'attestation_templates#preview'

      delete 'attestation_template/logo' => 'attestation_templates#delete_logo'
      delete 'attestation_template/signature' => 'attestation_templates#delete_signature'
    end

    namespace :instructeurs do
      get 'show' # delete after fixed tests admin/instructeurs/show_spec without this line
    end

    resources :gestionnaires, only: [:index, :create, :destroy]
  end

  #
  # Addresses
  #

  namespace :ban do
    get 'search' => 'search#get'
    get 'address_point' => 'search#get_address_point'
  end

  namespace :invites do
    post 'dossier/:dossier_id' => '/invites#create', as: 'dossier'
  end

  #
  # API
  #

  namespace :api do
    namespace :v1 do
      resources :procedures, only: [:index, :show] do
        resources :dossiers, only: [:index, :show]
      end
    end
  end

  #
  # User
  #

  scope module: 'new_user' do
    resources :dossiers, only: [:index, :show] do
      member do
        get 'identite'
        patch 'update_identite'
        get 'brouillon'
        patch 'brouillon', to: 'dossiers#update_brouillon'
        get 'modifier', to: 'dossiers#modifier'
        patch 'modifier', to: 'dossiers#update'
        get 'merci'
        get 'demande'
        get 'messagerie'
        post 'commentaire' => 'dossiers#create_commentaire'
        post 'ask_deletion'
        get 'attestation'
      end

      collection do
        post 'recherche'
      end
    end
    resource :feedback, only: [:create]
    get 'demarches' => 'demarches#index'
  end

  #
  # Gestionnaire
  #

  scope module: 'new_gestionnaire', as: 'gestionnaire' do
    resources :procedures, only: [:index, :show], param: :procedure_id do
      member do
        patch 'update_displayed_fields'
        get 'update_sort/:table/:column' => 'procedures#update_sort', as: 'update_sort'
        post 'add_filter'
        get 'remove_filter/:statut/:table/:column' => 'procedures#remove_filter', as: 'remove_filter'
        get 'download_dossiers'

        resources :dossiers, only: [:show], param: :dossier_id do
          member do
            get 'attestation'
            get 'messagerie'
            get 'annotations-privees' => 'dossiers#annotations_privees'
            get 'avis'
            get 'personnes-impliquees' => 'dossiers#personnes_impliquees'
            patch 'follow'
            patch 'unfollow'
            patch 'archive'
            patch 'unarchive'
            patch 'annotations' => 'dossiers#update_annotations'
            post 'commentaire' => 'dossiers#create_commentaire'
            post 'passer-en-instruction' => 'dossiers#passer_en_instruction'
            post 'repasser-en-construction' => 'dossiers#repasser_en_construction'
            post 'terminer'
            post 'send-to-instructeurs' => 'dossiers#send_to_instructeurs'
            scope :carte do
              get 'position'
            end
            post 'avis' => 'dossiers#create_avis'
            get 'print' => 'dossiers#print'
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

        get 'sign_up/email/:email' => 'avis#sign_up', constraints: { email: /.*/ }, as: 'sign_up'
        post 'sign_up/email/:email' => 'avis#create_gestionnaire', constraints: { email: /.*/ }
      end
    end
    get "recherche" => "recherche#index"
  end

  #
  # Administrateur
  #

  scope module: 'new_administrateur' do
    resources :procedures, only: [] do
      member do
        get 'apercu'
      end
    end

    resources :services, except: [:show] do
      collection do
        patch 'add_to_procedure'
      end
    end

    get 'profil' => 'profil#show'
    post 'renew-api-token' => 'profil#renew_api_token'
    # allow refresh 'renew api token' page
    get 'renew-api-token' => redirect('/profil')
  end

  apipie

  #
  # Legacy routes
  #

  get 'backoffice' => redirect('/procedures')
  get 'backoffice/sign_in' => redirect('/users/sign_in')
  get 'backoffice/dossiers/procedure/:procedure_id' => redirect('/procedures/%{procedure_id}')
end
