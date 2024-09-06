require 'sidekiq/web'
require 'sidekiq/cron/web'

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
      post 'hide_as_template', on: :member
      post 'unhide_as_template', on: :member
      post 'draft', on: :member
      post 'discard', on: :member
      post 'restore', on: :member
      put 'delete_administrateur', on: :member
      post 'add_administrateur_and_instructeur', on: :member
      post 'add_administrateur_with_confirmation', on: :member
      post 'change_piece_justificative_template', on: :member
      patch 'add_tags', on: :member
      patch 'update_template_status', on: :member
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

    resources :groupe_instructeurs, only: [:index, :show]

    resources :administrateurs, only: [:index, :show, :new, :create] do
      post 'reinvite', on: :member
      delete 'delete', on: :member
    end

    resources :users, only: [:index, :show, :edit, :update] do
      delete 'delete', on: :member
      post 'resend_confirmation_instructions', on: :member
      post 'resend_reset_password_instructions', on: :member
      put 'enable_feature', on: :member
      get 'emails', on: :member
      put 'unblock_email'
    end

    resources :experts, only: [:index, :show]

    resources :instructeurs, only: [:index, :show, :edit, :update] do
      post 'reinvite', on: :member
      delete 'delete', on: :member
    end

    if ENV['ADMINS_GROUP_ENABLED'] == 'enabled' || Rails.env.test? # can be removed if needed when EVERY PARTS of the feature will be merged / from env.example.optional
      resources :gestionnaires, only: [:index, :show, :edit, :update] do
        delete 'delete', on: :member
      end

      resources :groupe_gestionnaires, path: 'groupe_administrateurs', only: [:index, :show, :new, :create, :edit, :update] do
        post 'add_gestionnaire', on: :member
        delete 'remove_gestionnaire', on: :member
      end
    end

    resources :dossiers, only: [:show] do
      get 'transfer_edit', on: :member
      post 'transfer', on: :member
      delete 'transfer_destroy', on: :member
    end

    resources :bill_signatures, only: [:index]

    resources :exports, only: [:index, :show]

    resources :services, only: [:index, :show]

    resources :super_admins, only: [:index, :show, :destroy]

    resources :zones, only: [:index, :show]

    resources :team_accounts, only: [:index, :show]

    resources :email_events, only: [:index, :show] do
      post :generate_dolist_report, on: :collection
    end

    resources :dubious_procedures, only: [:index]
    resources :outdated_procedures, only: [:index] do
      patch :bulk_update, on: :collection
    end
    resources :safe_mailers, only: [:index, :edit, :update, :destroy, :new, :create, :show]

    authenticate :super_admin do
      mount Flipper::UI.app(-> { Flipper.instance }) => "/features", as: :flipper
      match "/delayed_job" => DelayedJobWeb, :anchor => false, :via => [:get, :post]
      mount MaintenanceTasks::Engine => "/maintenance_tasks"
      mount Sidekiq::Web => "/sidekiq"
    end

    get 'import_procedure_tags' => 'procedures#import_data'
    post 'import_tags' => 'procedures#import_tags'
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

  namespace :super_admins do
    resources :release_notes
  end

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
    post '/instructeurs/reset-link-sent' => 'users/sessions#reset_link_sent'
    get '/users/password/reset-link-sent' => 'users/passwords#reset_link_sent'
    get 'logout' => 'users/sessions#logout'
  end

  get 'password_complexity/:complexity' => 'password_complexity#show', as: 'show_password_complexity', constraints: { complexity: /\d/ }

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
    get 'particulier/mail_merge_with_existing_account/:email_merge_token' => 'particulier#mail_merge_with_existing_account', as: :particulier_mail_merge_with_existing_account
    post 'particulier/resend_and_renew_merge_confirmation' => 'particulier#resend_and_renew_merge_confirmation', as: :particulier_resend_and_renew_merge_confirmation
    post 'particulier/merge_with_existing_account' => 'particulier#merge_with_existing_account'
    post 'particulier/merge_with_new_account' => 'particulier#merge_with_new_account'
  end

  get '/auth/:provider' => 'omniauth#login', as: :omniauth, constraints: { :provider => /google|microsoft|yahoo|tatou|sipf/ }
  get '/auth/:provider/callback', to: 'omniauth#callback', as: :omniauth_callback, constraints: { :provider => /google|microsoft|yahoo|tatou|sipf/ }
  get '/auth/:provider/merge/:merge_token' => 'omniauth#merge', as: :omniauth_merge, constraints: { :provider => /google|microsoft|yahoo|tatou|sipf/ }
  get '/auth/:provider/mail_merge_with_existing_account/:merge_token' => 'omniauth#mail_merge_with_existing_account', as: :omniauth_mail_merge_with_existing_account, constraints: { :provider => /google|microsoft|yahoo|tatou|sipf/ }
  post '/auth/:provider/resend_and_renew_merge_confirmation' => 'omniauth#resend_and_renew_merge_confirmation', as: :omniauth_resend_and_renew_merge_confirmation, constraints: { :provider => /google|microsoft|yahoo|tatou|sipf/ }
  post '/auth/merge_with_existing_account' => 'omniauth#merge_with_existing_account', as: 'omniauth_merge_with_existing_account'
  post '/auth/merge_with_new_account' => 'omniauth#merge_with_new_account', as: 'omniauth_merge_with_new_account'

  namespace :agent_connect do
    get '' => 'agent#index'
    get 'login' => 'agent#login'
    get 'callback' => 'agent#callback'
  end

  namespace :champs do
    post ':dossier_id/:stable_id/repetition', to: 'repetition#add', as: :repetition
    delete ':dossier_id/:stable_id/repetition', to: 'repetition#remove'

    get ':dossier_id/:stable_id/siret', to: 'siret#show', as: :siret
    get ':dossier_id/:stable_id/rna', to: 'rna#show', as: :rna
    delete ':dossier_id/:stable_id/options', to: 'options#remove', as: :options
    get ':dossier_id/:stable_id/dn', to: 'numero_dn#show', as: :dn

    get ':dossier_id/:stable_id/carte/features', to: 'carte#index', as: :carte_features
    post ':dossier_id/:stable_id/carte/features', to: 'carte#create'
    patch ':dossier_id/:stable_id/carte/features/:id', to: 'carte#update', as: :carte_feature
    delete ':dossier_id/:stable_id/carte/features/:id', to: 'carte#destroy'

    get ':dossier_id/:stable_id/piece_justificative', to: 'piece_justificative#show', as: :piece_justificative
    put ':dossier_id/:stable_id/piece_justificative', to: 'piece_justificative#update'
    get ':dossier_id/:stable_id/piece_justificative/template', to: 'piece_justificative#template', as: :piece_justificative_template
    get ':dossier_id/:stable_id/piece_justificative/download/:h/(:i)', to: 'piece_justificative#download', as: :piece_justificative_download

    # TODO: remove after migration is ower
    get ':champ_id/siret', to: 'siret#show', as: :legacy_siret
    get ':champ_id/rna', to: 'rna#show', as: :legacy_rna
    delete ':champ_id/options', to: 'options#remove', as: :legacy_options
    get ':champ_id/dn', to: 'numero_dn#show', as: :legacy_dn

    get ':champ_id/carte/features', to: 'carte#index', as: :legacy_carte_features
    post ':champ_id/carte/features', to: 'carte#create'
    patch ':champ_id/carte/features/:id', to: 'carte#update'
    delete ':champ_id/carte/features/:id', to: 'carte#destroy'

    get ':champ_id/piece_justificative(/:h)', to: 'piece_justificative#show', as: :legacy_piece_justificative
    put ':champ_id/piece_justificative', to: 'piece_justificative#update'
    get ':champ_id/piece_justificative/template', to: 'piece_justificative#template'
    get ':champ_id/piece_justificative/download/:h/(:i)', to: 'piece_justificative#download', as: :legacy_piece_justificative_download
  end

  resources :attachments, only: [:show, :destroy]
  resources :recherche, only: [:index]

  get "patron" => "root#patron" if Rails.env.development? || Rails.env.test?
  get "suivi" => "root#suivi"
  post "save_locale" => "root#save_locale"

  get "contact", to: "support#index"
  post "contact", to: "support#create"

  get "contact-admin", to: "support#admin"

  get "mentions-legales", to: "static_pages#legal_notice"
  get "declaration-accessibilite", to: "static_pages#accessibility_statement"

  get "carte", to: "carte#show"

  post "webhooks/sendinblue", to: "webhook#sendinblue"
  post "webhooks/helpscout", to: "webhook#helpscout"
  post "webhooks/helpscout_support_dev", to: "webhook#helpscout_support_dev"
  match "webhooks/helpscout", to: lambda { |_| [204, {}, nil] }, via: :head

  get '/preremplir/:path', to: 'prefill_descriptions#edit', as: :preremplir
  get '/preremplir/:path/schema', to: 'api/public/v1/json_description_procedures#show', as: :prefill_json_description, defaults: { format: :json }
  resources :procedures, only: [], param: :path do
    member do
      resource :prefill_description, only: :update
      resources :prefill_type_de_champs, only: :show
    end
  end

  namespace :data_sources do
    get :adresse, to: 'adresse#search', as: :data_source_adresse
    get :commune, to: 'commune#search', as: :data_source_commune

    get :search_domaine_fonct, to: 'chorus#search_domaine_fonct', as: :search_domaine_fonct
    get :search_centre_couts, to: 'chorus#search_centre_couts', as: :search_centre_couts
    get :search_ref_programmation, to: 'chorus#search_ref_programmation', as: :search_ref_programmation
  end

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
    get 'procedures/archived', to: redirect('/admin/procedures?statut=archivees')
    get 'procedures/draft', to: redirect('/admin/procedures?statut=brouillons')

    namespace :assigns do
      get 'show' # delete after fixed tests admin/instructeurs/show_spec without this line
    end
  end

  #
  # te_fenua
  #
  get 'te_fenua/suggestions' => 'te_fenua#suggestions'

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

    namespace :public do
      namespace :v1 do
        resources :demarches, only: [] do
          member do
            resources :dossiers, only: [:create, :index]
            resources :stats, only: :index
          end
        end
      end
    end
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
      get '/:path/:provider', action: 'openid_connect', as: :openid_connect, constraints: { :provider => /google|microsoft|yahoo|tatou/ }
    end

    resources :dossiers, only: [:index, :show, :destroy, :new] do
      member do
        get 'identite'
        patch 'identite'
        patch 'update_identite'
        post 'clone'
        get 'siret'
        post 'siret', to: 'dossiers#update_siret'
        get 'etablissement'
        get 'etablissements'
        get 'brouillon'
        patch 'brouillon', to: 'dossiers#update'
        post 'brouillon', to: 'dossiers#submit_brouillon'
        get 'modifier', to: 'dossiers#modifier'
        post 'modifier', to: 'dossiers#submit_en_construction'
        patch 'modifier', to: 'dossiers#modifier_legacy'
        get 'champs/:stable_id', to: 'dossiers#champ', as: :champ
        get 'merci'
        get 'demande'
        get 'messagerie'
        post 'commentaire' => 'dossiers#create_commentaire'
        patch 'restore', to: 'dossiers#restore'
        get 'attestation'
        get 'qrcode/:created_at', action: 'qrcode', as: :qrcode
        get 'transferer', to: 'dossiers#transferer'
        get 'papertrail', format: :pdf
        get 'set_accuse_lecture_agreement_at'
      end

      collection do
        get 'transferer', to: 'dossiers#transferer_all'
        resources :transfers, only: [:create, :update, :destroy]
      end
    end

    resource :feedback, only: [:create]
    get 'demarches' => 'demarches#index'

    get 'profil' => 'profil#show'
    patch 'update_email' => 'profil#update_email'
    post 'transfer_all_dossiers' => 'profil#transfer_all_dossiers'
    post 'accept_merge' => 'profil#accept_merge'
    post 'refuse_merge' => 'profil#refuse_merge'
    delete 'france_connect_information' => 'profil#destroy_fci'
    patch 'preferred_domain', to: 'profil#preferred_domain'
    get 'fermeture/:path', to: 'commencer#closing_details', as: :closing_details
  end

  get 'procedures/:id/logo', to: 'procedures#logo', as: :procedure_logo

  #
  # Expert
  #
  scope module: 'experts', as: 'expert' do
    get 'avis', to: 'avis#index', as: 'all_avis'

    resources :procedures, only: [], param: :procedure_id do
      member do
        get 'notification_settings', to: 'avis#notification_settings'
        patch 'update_notification_settings', to: 'avis#update_notification_settings'

        resources :avis, only: [:show, :update] do
          get '', action: 'procedure', on: :collection, as: :procedure
          member do
            get 'instruction'
            get 'avis_list'
            get 'avis_new'
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
          resource :contact_information
          member do
            post 'add_instructeur'
            delete 'remove_instructeur'
            post 'add_signature'
            get 'preview_attestation'
          end
        end

        resources :avis, only: [] do
          member do
            patch 'revoquer'
            get 'remind'
          end
        end

        patch 'update_displayed_fields'
        get 'update_sort/:table/:column' => 'procedures#update_sort', as: 'update_sort'
        post 'add_filter'
        post 'update_filter'
        get 'remove_filter'
        get 'download_export'
        post 'download_export'
        get 'polling_last_export'
        get 'stats'
        get 'exports'
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
            get 'geo_data'
            get 'apercu_attestation'
            get 'bilans_bdf'
            get 'messagerie'
            get 'annotations-privees' => 'dossiers#annotations_privees'
            get 'avis'
            get 'avis_new'
            get 'personnes-impliquees' => 'dossiers#personnes_impliquees'
            get 'annotations/:stable_id', to: 'dossiers#annotation', as: :annotation
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
            post 'pending_correction'
            post 'send-to-instructeurs' => 'dossiers#send_to_instructeurs'
            post 'avis' => 'dossiers#create_avis'
            get 'print' => 'dossiers#print'
            get 'telecharger_pjs' => 'dossiers#telecharger_pjs'
            get 'reaffectation'
            get 'pieces_jointes'
            post 'reaffecter'
          end
        end

        resources :batch_operations, only: [:create]
      end
    end
  end

  if ENV['ADMINS_GROUP_ENABLED'] == 'enabled' || Rails.env.test? # can be removed if needed when EVERY PARTS of the feature will be merged / from env.example.optional

    #
    # Gestionnaire
    #

    scope module: 'gestionnaires', as: 'gestionnaire' do
      resources :groupe_gestionnaires, path: 'groupes', only: [:index, :show, :create, :edit, :update, :destroy] do
        resources :gestionnaires, controller: 'groupe_gestionnaire_gestionnaires', only: [:index, :create, :destroy]
        resources :administrateurs, controller: 'groupe_gestionnaire_administrateurs', only: [:index, :create, :destroy] do
          delete :remove, on: :member
        end
        resources :children, controller: 'groupe_gestionnaire_children', only: [:index, :create, :destroy]
        resources :commentaires, controller: 'groupe_gestionnaire_commentaires', only: [:index, :show, :create, :destroy] do
          collection do
            get 'parent_groupe_gestionnaire'
            post 'create_parent_groupe_gestionnaire'
          end
        end
        member do
          get :tree_structure, path: 'arborescence'
        end
      end
    end

    namespace :gestionnaires do
      get 'activate' => '/gestionnaires/activate#new'
      patch 'activate' => '/gestionnaires/activate#create'
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
        get 'all' if Rails.application.config.ds_zonage_enabled
        get 'administrateurs' if Rails.application.config.ds_zonage_enabled
      end

      member do
        post 'detail'
        get 'apercu'
        get 'champs'
        get 'zones'
        get 'annotations'
        get 'modifications'
        get 'monavis'
        patch 'update_monavis'
        get 'accuse_lecture'
        patch 'update_accuse_lecture'
        get 'jeton'
        patch 'update_jeton'
        put :allow_expert_review
        put :allow_expert_messaging
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

      resources :routing_rules, only: [:update, :destroy], param: :groupe_instructeur_id do
        patch :add_row, on: :member
        patch :change_targeted_champ, on: :member
        delete :delete_row, on: :member
      end

      patch :update_defaut_groupe_instructeur, controller: 'routing_rules', as: :update_defaut_groupe_instructeur

      put 'clone'
      put 'archive'
      get 'publication' => 'procedures#publication', as: :publication
      get 'check_path' => 'procedures#check_path', as: :check_path
      put 'publish' => 'procedures#publish', as: :publish
      put 'reset_draft' => 'procedures#reset_draft', as: :reset_draft
      put 'publish_revision' => 'procedures#publish_revision', as: :publish_revision
      get 'transfert' => 'procedures#transfert', as: :transfert
      get 'close' => 'procedures#close', as: :close
      get 'closing_notification' => 'procedures#closing_notification', as: :closing_notification
      post 'notify_after_closing' => 'procedures#notify_after_closing', as: :notify_after_closing
      get 'confirmation' => 'procedures#confirmation', as: :confirmation
      post 'transfer' => 'procedures#transfer', as: :transfer
      resources :mail_templates, only: [:edit, :update, :show]

      resources :groupe_instructeurs, only: [:index, :show, :create, :update, :destroy] do
        patch 'update_state' => 'groupe_instructeurs#update_state'

        member do
          post 'add_instructeur'
          delete 'remove_instructeur'
          get 'reaffecter_dossiers'
          post 'reaffecter'
          post 'add_signature'
          get 'preview_attestation'
        end

        collection do
          get 'options'
          get 'ajout'
          post 'ajout' => 'groupe_instructeurs#create'
          patch 'wizard'
          get 'simple_routing'
          post 'create_simple_routing'
          delete 'destroy_all_groups_but_defaut'
          patch 'update_instructeurs_self_management_enabled'
          post 'import'
          get 'export_groupe_instructeurs'
        end
      end

      resources :administrateurs, controller: 'procedure_administrateurs', only: [:index, :create, :destroy]

      resources :experts, controller: 'experts_procedures', only: [:index, :create, :update, :destroy]

      resources :types_de_champ, only: [:create, :update, :destroy], param: :stable_id do
        member do
          patch :move_and_morph
          patch :move_up
          patch :move_down
          put :piece_justificative_template
          put :notice_explicative
        end
      end

      resources :mail_templates, only: [:index] do
        get 'preview', on: :member
      end

      resource :attestation_template, only: [:show, :edit, :update, :create] do
        get 'preview', on: :member
      end
      resource :chorus, only: [:edit, :update] do
        get 'add_champ_engagement_juridique'
      end

      resource :attestation_template_v2, only: [:show, :edit, :update, :create]

      resource :dossier_submitted_message, only: [:edit, :update, :create]
      # ADDED TO ACCESS IT FROM THE IFRAME
      get 'attestation_template/preview' => 'attestation_templates#preview'

      resource :sva_svr, only: [:show, :edit, :update], controller: 'sva_svr'
    end

    get 'mon-groupe' => 'groupe_gestionnaire#show', as: :groupe_gestionnaire
    get 'mon-groupe/administrateurs' => 'groupe_gestionnaire#administrateurs', as: :groupe_gestionnaire_administrateurs
    get 'mon-groupe/gestionnaires' => 'groupe_gestionnaire#gestionnaires', as: :groupe_gestionnaire_gestionnaires
    get 'mon-groupe/commentaires' => 'groupe_gestionnaire#commentaires', as: :groupe_gestionnaire_commentaires
    post 'mon-groupe/create_commentaire' => 'groupe_gestionnaire#create_commentaire', as: :groupe_gestionnaire_create_commentaire

    resources :services, except: [:show] do
      collection do
        patch 'add_to_procedure'
      end
    end

    resources :api_tokens, only: [:create, :destroy, :edit, :update] do
      collection do
        get :nom
        get :autorisations
        get :securite
      end
    end
  end

  resources :release_notes, only: [:index]

  resources :faq, only: [:index]
  get '/faq/:category/:slug', to: 'faq#show', as: :faq

  get '/404', to: 'errors#not_found'
  get '/422', to: 'errors#unprocessable_entity'
  get '/500', to: 'errors#internal_server_error'
  get '/:status', to: 'errors#show', constraints: { status: /[4-5][0-5]\d/ }

  if Rails.env.test?
    scope 'test/api_geo' do
      get 'regions' => 'api_geo_test#regions'
      get 'communes' => 'api_geo_test#communes'
      get 'departements' => 'api_geo_test#departements'
      get 'departements/:code/communes' => 'api_geo_test#communes'
    end
  end

  resource :recovery, only: [], path: :recuperation_de_dossiers do
    collection do
      get :nature
      post :nature, action: :post_nature
      get :identification
      post :identification, action: :post_identification
      get :selection
      post :selection, action: :post_selection
      get :terminee
      get :support
    end

    root action: :nature
  end
  #
  # Legacy routes
  #
  get 'demandes/new' => redirect(DEMANDE_INSCRIPTION_ADMIN_PAGE_URL)

  get 'backoffice' => redirect('/procedures')
  get 'backoffice/sign_in' => redirect('/users/sign_in')
  get 'backoffice/dossiers/procedure/:procedure_id' => redirect('/procedures/%{procedure_id}')
end
