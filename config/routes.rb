Rails.application.routes.draw do
  #
  # Manager
  #

  get 'manager/sign_in' => 'administrations/sessions#new'
  delete 'manager/sign_out' => 'administrations/sessions#destroy'
  namespace :manager do
    resources :procedures, only: [:index, :show] do
      post 'whitelist', on: :member
      post 'draft', on: :member
      post 'hide', on: :member
      post 'add_administrateur', on: :member
      post 'change_piece_justificative_template', on: :member
    end

    resources :dossiers, only: [:index, :show] do
      post 'change_state_to_instruction', on: :member
      post 'hide', on: :member
    end

    resources :administrateurs, only: [:index, :show, :new, :create] do
      post 'reinvite', on: :member
      put 'enable_feature', on: :member
    end

    resources :users, only: [:index, :show] do
      post 'resend_confirmation_instructions', on: :member
    end

    resources :gestionnaires, only: [:index, :show] do
      post 'reinvite', on: :member
      put 'enable_feature', on: :member
    end

    resources :dossiers, only: [:show]

    resources :demandes, only: [:index]

    resources :bill_signatures, only: [:index]

    resources :services, only: [:index, :show]

    post 'demandes/create_administrateur'
    post 'demandes/refuse_administrateur'

    authenticate :administration do
      mount Flipflop::Engine => "/features"
      match "/delayed_job" => DelayedJobWeb, :anchor => false, :via => [:get, :post]
    end

    root to: "administrateurs#index"
  end

  #
  # Letter Opener
  #

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
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
    confirmations: 'users/confirmations',
    passwords: 'users/passwords'
  }

  devise_scope :user do
    get '/users/sign_in/demo' => redirect("/users/sign_in")
    get '/users/no_procedure' => 'users/sessions#no_procedure'
    get 'connexion-par-jeton/:id' => 'users/sessions#sign_in_by_link', as: 'sign_in_by_link'
    get 'lien-envoye/:email' => 'users/sessions#link_sent', constraints: { email: /.*/ }, as: 'link_sent'
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
  get '/administration' => 'root#administration'

  get 'users' => 'users#index'
  get 'admin' => 'admin#index'

  get '/stats' => 'stats#index'
  get '/stats/download' => 'stats#download'
  resources :demandes, only: [:new, :create]

  namespace :france_connect do
    get 'particulier' => 'particulier#login'
    get 'particulier/callback' => 'particulier#callback'
  end

  namespace :champs do
    get ':position/siret', to: 'siret#show', as: :siret
    get ':position/dossier_link', to: 'dossier_link#show', as: :dossier_link
    post ':position/carte', to: 'carte#show', as: :carte
    post ':position/repetition', to: 'repetition#show', as: :repetition
  end

  get 'attachments/:id', to: 'attachments#show', as: :attachment
  delete 'attachments/:id', to: 'attachments#destroy'

  get 'tour-de-france' => 'root#tour_de_france'
  get "patron" => "root#patron"
  get "accessibilite" => "root#accessibilite"
  get "suivi" => "root#suivi"

  get "contact", to: "support#index"
  post "contact", to: "support#create"

  get "contact-admin", to: "support#admin"

  post "webhooks/helpscout", to: "webhook#helpscout"
  match "webhooks/helpscout", to: lambda { |_| [204, {}, nil] }, via: :head

  #
  # Deprecated UI
  #

  namespace :users do
    resources :dossiers, only: [] do
      post '/carte/zones' => 'carte#zones'
      get '/carte' => 'carte#show'
      post '/carte' => 'carte#save'
    end

    # Redirection of legacy "/users/dossiers" route to "/dossiers"
    get 'dossiers', to: redirect('/dossiers')
    get 'dossiers/:id/recapitulatif', to: redirect('/dossiers/%{id}')
    get 'dossiers/invites/:id', to: redirect(path: '/invites/%{id}')
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

    resources :procedures do
      collection do
        get 'new_from_existing' => 'procedures#new_from_existing', as: :new_from_existing
      end

      member do
        delete :delete_logo
        delete :delete_deliberation
        delete :delete_notice
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

  get 'address/suggestions' => 'address#suggestions'
  get 'address/geocode' => 'address#geocode'

  resources :invites, only: [:show] do
    collection do
      post 'dossier/:dossier_id', to: 'invites#create', as: :dossier
    end
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

  scope module: 'users' do
    namespace :commencer do
      get '/test/:path', action: 'commencer_test', as: :test
      get '/:path', action: 'commencer'
      get '/:path/sign_in', action: 'sign_in', as: :sign_in
      get '/:path/sign_up', action: 'sign_up', as: :sign_up
      get '/:path/france_connect', action: 'france_connect', as: :france_connect
    end

    resources :dossiers, only: [:index, :show, :new] do
      member do
        get 'identite'
        patch 'update_identite'
        get 'siret'
        post 'siret', to: 'dossiers#update_siret'
        get 'etablissement'
        get 'brouillon'
        patch 'brouillon', to: 'dossiers#update_brouillon'
        get 'modifier', to: 'dossiers#modifier'
        patch 'modifier', to: 'dossiers#update'
        get 'merci'
        get 'demande'
        get 'messagerie'
        get 'operations_logs'
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

  scope module: 'gestionnaires', as: 'gestionnaire' do
    resources :procedures, only: [:index, :show], param: :procedure_id do
      member do
        patch 'update_displayed_fields'
        get 'update_sort/:table/:column' => 'procedures#update_sort', as: 'update_sort'
        post 'add_filter'
        get 'remove_filter' => 'procedures#remove_filter', as: 'remove_filter'
        get 'download_dossiers'
        get 'email_notifications'
        patch 'update_email_notifications'

        resources :dossiers, only: [:show], param: :dossier_id do
          member do
            get 'attestation'
            get 'apercu_attestation'
            get 'messagerie'
            get 'operations_logs'
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
    resources :procedures, only: [:update] do
      member do
        get 'apercu'
        get 'champs'
        get 'annotations'
      end

      resources :administrateurs, controller: 'procedure_administrateurs', only: [:index, :create, :destroy]

      resources :types_de_champ, only: [:create, :update, :destroy] do
        member do
          patch :move
        end
      end

      resources :mail_templates, only: [] do
        get 'preview', on: :member
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

  #
  # Legacy routes
  #

  get 'backoffice' => redirect('/procedures')
  get 'backoffice/sign_in' => redirect('/users/sign_in')
  get 'backoffice/dossiers/procedure/:procedure_id' => redirect('/procedures/%{procedure_id}')
end
