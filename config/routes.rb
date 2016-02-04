Rails.application.routes.draw do

  devise_for :administrateurs, controllers: {
                                 sessions: 'administrateurs/sessions'
                             }, skip: [:password, :registrations]

  devise_for :gestionnaires, controllers: {
                               sessions: 'gestionnaires/sessions'
                           }, skip: [:password, :registrations]

  devise_for :users, controllers: {
                       sessions: 'users/sessions',
                       registrations: 'users/registrations'
                   }

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
    resources :dossiers do
      get '/description' => 'description#show'
      get '/description/error' => 'description#error'
      post 'description' => 'description#create'
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
    end
    resource :dossiers
  end

  get 'admin' => 'admin#index'

  namespace :admin do
    get 'sign_in' => '/administrateurs/sessions#new'
    get 'procedures/archived' => 'procedures#archived'
    get 'profile' => 'profile#show', as: :profile
    resources :procedures do
      resource :types_de_champ, only: [:show, :update] do
        post '/:index/move_up' => 'types_de_champ#move_up', as: :move_up
        post '/:index/move_down' => 'types_de_champ#move_down', as: :move_down
      end

      put 'archive' => 'procedures#archive', as: :archive

      resources :types_de_champ, only: [:destroy]
      resource :pieces_justificatives, only: [:show, :update]
      resources :pieces_justificatives, only: :destroy
    end
  end

  get 'backoffice' => 'backoffice#index'

  namespace :backoffice do
    get 'sign_in' => '/gestionnaires/sessions#new'

    get 'dossiers/search' => 'dossiers#search'

    resources :dossiers do
      post 'valid' => 'dossiers#valid'
      post 'close' => 'dossiers#close'
    end

    resources :commentaires, only: [:create]
  end

  namespace :api do
    namespace :v1 do
      resources :procedures, only: [:index, :show] do
        resources :dossiers, only: [:index, :show]
      end
    end
  end
end
