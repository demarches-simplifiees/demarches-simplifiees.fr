class Users::PasswordsController < Devise::PasswordsController
  after_action :try_to_authenticate_gestionnaire, only: [:update]
  after_action :try_to_authenticate_administrateur, only: [:update]

  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  # def create
  #   super
  # end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  def try_to_authenticate_gestionnaire
    if user_signed_in?
      gestionnaire = Gestionnaire.find_by(email: current_user.email)

      if gestionnaire
        sign_in gestionnaire
      end
    end
  end

  def try_to_authenticate_administrateur
    if user_signed_in?
      administrateur = Administrateur.find_by(email: current_user.email)

      if administrateur
        sign_in administrateur
      end
    end
  end
end
