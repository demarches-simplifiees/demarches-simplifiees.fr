Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  get '/saml/auth' => 'saml_idp#new'
  post '/saml/auth' => 'saml_idp#create'
  get '/saml/metadata' => 'saml_idp#show'

  #
  # Manager
  #

  namespace :manager do
    resources :procedures, only: [:index, :show, :edit, :update] do
      post 'whitelist', on: :member
      post 'draft', on: :member
      post 'discard', on: :member
      post 'restore', on: :member
      put 'delete_administrateur', on: :member
      post 'add_administrateur_and_instructeur', on: :member
      post 'add_administrateur_with_confirmation', on: :member
      post 'change_piece_justificative_template', on: :member
      patch 'add_tags', on: :member
      get 'export_mail_brouillons', on: :member
      resources :confirmation_urls, only: :new
      resources :administrateur_confirmations, only: [:new, :create]
    end

    resources :archives, only: [:index, :show]

    resources :dossiers, only: [:index, :show] do
      post 'discard', on: :member
      post 'restore', on: :member
      post 'repasser_en_instruction', on: :member
    end

    resources :administrateurs, only: [:index, :show, :new, :create] do
      post 'reinvite', on: :member
      delete 'delete', on: :member
    end

    resources :users, only: [:index, :show, :edit, :update] do
      delete 'delete', on: :member
      post 'resend_confirmation_instructions', on: :member
      put 'enable_feature', on: :member
      get 'emails', on: :member
      put 'unblock_email'
    end

    resources :instructeurs, only: [:index, :show, :edit, :update] do
      post 'reinvite', on: :member
      delete 'delete', on: :member
    end

    resources :dossiers, only: [:show]

    resources :demandes, only: [:index]

    resources :bill_signatures, only: [:index]

    resources :services, only: [:index, :show]

    resources :super_admins, only: [:index, :show, :destroy]

    resources :zones, only: [:index, :show]

    resources :team_accounts, only: [:index, :show]

    resources :dubious_procedures, only: [:index]
    resources :outdated_procedures, only: [:index] do
      patch :bulk_update, on: :collection
    end

    post 'demandes/create_administrateur'
    post 'demandes/refuse_administrateur'

    authenticate :super_admin do
      mount Flipper::UI.app(-> { Flipper.instance }) => "/features", as: :flipper
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

  get "/ping" => "ping#index"

  #
  # Authentication
  #

  devise_for :super_admins, skip: [:registrations], controllers: {
    sessions: 'super_admins/sessions',
    passwords: 'super_admins/passwords'
  }

  get 'super_admins/edit_otp', to: 'super_admins#edit_otp', as: 'edit_super_admin_otp'
  put 'super_admins/enable_otp', to: 'super_admins#enable_otp', as: 'enable_super_admin_otp'

  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    confirmations: 'users/confirmations',
    passwords: 'users/passwords'
  }

  devise_scope :user do
    get '/users/no_procedure' => 'users/sessions#no_procedure'
    get 'connexion-par-jeton/:id' => 'users/sessions#sign_in_by_link', as: 'sign_in_by_link'
    get 'lien-envoye' => 'users/sessions#link_sent', as: 'link_sent'
    get '/users/password/reset-link-sent' => 'users/passwords#reset_link_sent'
  end

  get 'password_complexity' => 'password_complexity#show', as: 'show_password_complexity'

  resources :targeted_user_links, only: [:show]

  #
  # Main routes
  #

  root 'root#index'
  get '/administration' => 'root#administration'

  get 'users' => 'users#index'
  get 'admin' => 'admin#index'

  get '/stats' => 'stats#index'
  get '/stats/download' => 'stats#download'

  namespace :france_connect do
    get 'particulier' => 'particulier#login'
    get 'particulier/callback' => 'particulier#callback'
    get 'particulier/merge/:merge_token' => 'particulier#merge', as: :particulier_merge
    get 'particulier/mail_merge_with_existing_account/:merge_token' => 'particulier#mail_merge_with_existing_account', as: :particulier_mail_merge_with_existing_account
    post 'particulier/resend_and_renew_merge_confirmation' => 'particulier#resend_and_renew_merge_confirmation', as: :particulier_resend_and_renew_merge_confirmation
    post 'particulier/merge_with_existing_account' => 'particulier#merge_with_existing_account'
    post 'particulier/merge_with_new_account' => 'particulier#merge_with_new_account'
  end

  namespace :agent_connect do
    get '' => 'agent#index'
    get 'login' => 'agent#login'
    get 'callback' => 'agent#callback'
  end

  namespace :champs do
    get ':champ_id/siret', to: 'siret#show', as: :siret
    get ':champ_id/rna', to: 'rna#show', as: :rna
    get ':champ_id/dossier_link', to: 'dossier_link#show', as: :dossier_link
    post ':champ_id/repetition', to: 'repetition#add', as: :repetition
    delete ':champ_id/repetition', to: 'repetition#remove'

    get ':champ_id/carte/features', to: 'carte#index', as: :carte_features
    post ':champ_id/carte/features', to: 'carte#create'
    patch ':champ_id/carte/features/:id', to: 'carte#update'
    delete ':champ_id/carte/features/:id', to: 'carte#destroy'

    get ':champ_id/piece_justificative', to: 'piece_justificative#show', as: :piece_justificative
    put ':champ_id/piece_justificative', to: 'piece_justificative#update', as: :attach_piece_justificative
    get ':champ_id/piece_justificative/template', to: 'piece_justificative#template', as: :piece_justificative_template
  end

  resources :attachments, only: [:show, :destroy]
  resources :recherche, only: [:index]

  get "patron" => "root#patron"
  get "suivi" => "root#suivi"
  post "dismiss_outdated_browser" => "root#dismiss_outdated_browser"
  post "save_locale" => "root#save_locale"

  get "contact", to: "support#index"
  post "contact", to: "support#create"

  get "contact-admin", to: "support#admin"

  post "webhooks/helpscout", to: "webhook#helpscout"
  post "webhooks/helpscout_support_dev", to: "webhook#helpscout_support_dev"
  match "webhooks/helpscout", to: lambda { |_| [204, {}, nil] }, via: :head

  #
  # Deprecated UI
  #

  namespace :users do
    resources :dossiers, only: [] do
      post '/carte/zones' => 'carte#zones'
      get '/carte' => 'carte#show'
      post '/carte' => 'carte#save'
      post '/repousser-expiration' => 'dossiers#extend_conservation'
    end

    # Redirection of legacy "/users/dossiers" route to "/dossiers"
    get 'dossiers', to: redirect('/dossiers')
    get 'dossiers/:id/recapitulatif', to: redirect('/dossiers/%{id}')
    get 'dossiers/invites/:id', to: redirect(path: '/invites/%{id}')

    get 'activate' => '/users/activate#new'
    patch 'activate' => '/users/activate#create'
  end

  # order matters: we don't want those routes to match /admin/procedures/:id
  get 'admin/procedures/new' => 'administrateurs/procedures#new', as: :new_admin_procedure

  namespace :admin do
    get 'activate' => '/administrateurs/activate#new'
    patch 'activate' => '/administrateurs/activate#create'
    get 'procedures/archived', to: redirect('/admin/procedures?statut=archivees')
    get 'procedures/draft', to: redirect('/admin/procedures?statut=brouillons')

    namespace :assigns do
      get 'show' # delete after fixed tests admin/instructeurs/show_spec without this line
    end
  end

  resources :invites, only: [:show, :destroy] do
    collection do
      post 'dossier/:dossier_id', to: 'invites#create', as: :dossier
    end
  end

  #
  # API
  #

  get 'graphql/schema' => redirect('/graphql/schema/index.html')
  get 'graphql', to: "graphql#playground"

  namespace :api do
    namespace :v1 do
      resources :procedures, only: [:index, :show] do
        resources :dossiers, only: [:index, :show]
      end
    end

    namespace :v2 do
      post :graphql, to: "graphql#execute"
      get 'dossiers/pdf/:id', format: :pdf, to: "dossiers#pdf", as: :dossier_pdf
      get 'dossiers/geojson/:id', to: "dossiers#geojson", as: :dossier_geojson
    end

    resources :pays, only: :index
  end

  #
  # User
  #

  scope module: 'users' do
    namespace :statistiques do
      get '/:path', action: 'statistiques'
    end

    namespace :commencer do
      get '/test/:path/dossier_vide', action: :dossier_vide_pdf_test, as: :dossier_vide_test
      get '/test/:path', action: 'commencer_test', as: :test
      get '/:path', action: 'commencer'
      get '/:path/dossier_vide', action: 'dossier_vide_pdf', as: :dossier_vide
      get '/:path/sign_in', action: 'sign_in', as: :sign_in
      get '/:path/sign_up', action: 'sign_up', as: :sign_up
      get '/:path/france_connect', action: 'france_connect', as: :france_connect
    end

    resources :dossiers, only: [:index, :show, :new] do
      member do
        get 'identite'
        patch 'update_identite'
        post 'clone'
        get 'siret'
        post 'siret', to: 'dossiers#update_siret'
        get 'etablissement'
        get 'brouillon'
        patch 'brouillon', to: 'dossiers#update_brouillon'
        post 'brouillon', to: 'dossiers#submit_brouillon'
        get 'modifier', to: 'dossiers#modifier'
        patch 'modifier', to: 'dossiers#update'
        get 'merci'
        get 'demande'
        get 'messagerie'
        post 'commentaire' => 'dossiers#create_commentaire'
        patch 'delete_dossier'
        patch 'restore', to: 'dossiers#restore'
        get 'attestation'
        get 'transferer', to: 'dossiers#transferer'
        get 'papertrail', format: :pdf
      end

      collection do
        get 'transferer', to: 'dossiers#transferer_all'
        get 'recherche'
        resources :transfers, only: [:create, :update, :destroy]
      end
    end

    resource :feedback, only: [:create]
    get 'demarches' => 'demarches#index'

    get 'profil' => 'profil#show'
    post 'renew-api-token' => 'profil#renew_api_token'
    # allow refresh 'renew api token' page
    get 'renew-api-token' => redirect('/profil')
    patch 'update_email' => 'profil#update_email'
    post 'transfer_all_dossiers' => 'profil#transfer_all_dossiers'
    post 'accept_merge' => 'profil#accept_merge'
    post 'refuse_merge' => 'profil#refuse_merge'
    delete 'france_connect_information' => 'profil#destroy_fci'
  end

  #
  # Expert
  #
  scope module: 'experts', as: 'expert' do
    get 'avis', to: 'avis#index', as: 'all_avis'

    resources :procedures, only: [], param: :procedure_id do
      member do
        resources :avis, only: [:show, :update] do
          get '', action: 'procedure', on: :collection, as: :procedure
          member do
            get 'instruction'
            get 'messagerie'
            post 'commentaire' => 'avis#create_commentaire'
            post 'avis' => 'avis#create_avis'
            get 'bilans_bdf'
            get 'telecharger_pjs' => 'avis#telecharger_pjs'

            get 'sign_up' => 'avis#sign_up'
            post 'sign_up' => 'avis#update_expert'

            # This redirections are ephemeral, to ensure that emails sent to experts before are still valid
            # TODO : remove these lines after September, 2021
            get 'sign_up/email/:email' => 'avis#sign_up', constraints: { email: /.*/ }, as: 'sign_up_legacy'
            post 'sign_up/email/:email' => 'avis#update_expert', constraints: { email: /.*/ }, as: 'update_expert_legacy'
          end
        end
      end
    end
  end

  #
  # Instructeur
  #

  scope module: 'instructeurs', as: 'instructeur' do
    resources :procedures, only: [:index, :show], param: :procedure_id do
      member do
        resources :archives, only: [:index, :create]

        resources :groupes, only: [:index, :show], controller: 'groupe_instructeurs' do
          member do
            post 'add_instructeur'
            delete 'remove_instructeur'
          end
        end

        resources :avis, only: [:show, :update] do
          get '', action: 'procedure', on: :collection, as: :procedure
          member do
            patch 'revoquer'
            get 'revive'
          end
        end

        patch 'update_displayed_fields'
        get 'update_sort/:table/:column' => 'procedures#update_sort', as: 'update_sort'
        post 'add_filter'
        get 'remove_filter' => 'procedures#remove_filter', as: 'remove_filter'
        get 'download_export'
        post 'download_export'
        get 'stats'
        get 'email_notifications'
        get 'administrateurs'
        patch 'update_email_notifications'
        get 'deleted_dossiers'
        get 'email_usagers'
        post 'create_multiple_commentaire'

        resources :dossiers, only: [:show, :destroy], param: :dossier_id do
          member do
            resources :commentaires, only: [:destroy]
            post 'repousser-expiration' => 'dossiers#extend_conservation'
            get 'attestation'
            get 'geo_data'
            get 'apercu_attestation'
            get 'bilans_bdf'
            get 'messagerie'
            get 'annotations-privees' => 'dossiers#annotations_privees'
            get 'avis'
            get 'personnes-impliquees' => 'dossiers#personnes_impliquees'
            patch 'follow'
            patch 'unfollow'
            patch 'archive'
            patch 'unarchive'
            patch 'restore'
            patch 'annotations' => 'dossiers#update_annotations'
            post 'commentaire' => 'dossiers#create_commentaire'
            post 'passer-en-instruction' => 'dossiers#passer_en_instruction'
            post 'repasser-en-construction' => 'dossiers#repasser_en_construction'
            post 'repasser-en-instruction' => 'dossiers#repasser_en_instruction'
            post 'terminer'
            post 'send-to-instructeurs' => 'dossiers#send_to_instructeurs'
            post 'avis' => 'dossiers#create_avis'
            get 'print' => 'dossiers#print'
            get 'telecharger_pjs' => 'dossiers#telecharger_pjs'
          end
        end

        resources :batch_operations, only: [:create]
      end
    end
  end

  #
  # Administrateur
  #

  scope module: 'administrateurs', path: 'admin', as: 'admin' do
    resources :procedures do
      resources :archives, only: [:index, :create]
      resources :exports, only: [] do
        collection do
          get 'download'
          post 'download'
        end
      end

      collection do
        get 'new_from_existing'
        post 'search'
        get 'all'
        get 'administrateurs'
      end

      member do
        get 'apercu'
        get 'champs'
        get 'zones'
        get 'annotations'
        get 'modifications'
        get 'monavis'
        patch 'update_monavis'
        get 'jeton'
        patch 'update_jeton'
        put :allow_expert_review
        put :experts_require_administrateur_invitation
        put :restore
      end

      get :api_particulier, controller: 'jeton_particulier'

      resource 'api_particulier', only: [] do
        resource 'jeton', only: [:show, :update], controller: 'jeton_particulier'
        resource 'sources', only: [:show, :update], controller: 'sources_particulier'
      end

      resources :conditions, only: [:update, :destroy], param: :stable_id do
        patch :add_row, on: :member
        patch :change_targeted_champ, on: :member
        delete :delete_row, on: :member
      end

      put 'clone'
      put 'archive'
      get 'publication' => 'procedures#publication', as: :publication
      put 'publish' => 'procedures#publish', as: :publish
      put 'reset_draft' => 'procedures#reset_draft', as: :reset_draft
      get 'transfert' => 'procedures#transfert', as: :transfert
      get 'close' => 'procedures#close', as: :close
      post 'transfer' => 'procedures#transfer', as: :transfer
      resources :mail_templates, only: [:edit, :update, :show]

      resources :groupe_instructeurs, only: [:index, :show, :create, :update, :destroy] do
        member do
          post 'add_instructeur'
          delete 'remove_instructeur'
          get 'reaffecter_dossiers'
          post 'reaffecter'
        end

        collection do
          patch 'update_routing_criteria_name'
          patch 'update_instructeurs_self_management_enabled'
          post 'import'
          get 'export_groupe_instructeurs'
        end
      end

      resources :administrateurs, controller: 'procedure_administrateurs', only: [:index, :create, :destroy]

      resources :experts, controller: 'experts_procedures', only: [:index, :create, :update, :destroy]

      resources :types_de_champ, only: [:create, :update, :destroy], param: :stable_id do
        member do
          patch :move
          patch :move_up
          patch :move_down
          put :piece_justificative_template
        end
      end

      resources :mail_templates, only: [:index] do
        get 'preview', on: :member
      end

      resource :attestation_template, only: [:show, :edit, :update, :create] do
        get 'preview', on: :member
      end
      resource :dossier_submitted_message, only: [:edit, :update, :create]
      # ADDED TO ACCESS IT FROM THE IFRAME
      get 'attestation_template/preview' => 'attestation_templates#preview'
    end

    resources :services, except: [:show] do
      collection do
        patch 'add_to_procedure'
      end
    end
  end

  if Rails.env.test?
    scope 'test/api_geo' do
      get 'regions' => 'api_geo_test#regions'
      get 'communes' => 'api_geo_test#communes'
      get 'departements' => 'api_geo_test#departements'
      get 'departements/:code/communes' => 'api_geo_test#communes'
    end
  end

  #
  # Legacy routes
  #
  get 'demandes/new' => redirect(DEMANDE_INSCRIPTION_ADMIN_PAGE_URL)

  get 'backoffice' => redirect('/procedures')
  get 'backoffice/sign_in' => redirect('/users/sign_in')
  get 'backoffice/dossiers/procedure/:procedure_id' => redirect('/procedures/%{procedure_id}')
end
