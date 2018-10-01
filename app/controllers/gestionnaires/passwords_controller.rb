class Gestionnaires::PasswordsController < Devise::PasswordsController
  after_action :try_to_authenticate_user, only: %i(update)
  after_action :try_to_authenticate_administrateur, only: %i(update)

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

  def try_to_authenticate_user
    if gestionnaire_signed_in?
      user = User.find_by(email: current_gestionnaire.email)

      if user
        sign_in user
      end
    end
  end

  def try_to_authenticate_administrateur
    if gestionnaire_signed_in?
      administrateur = Administrateur.find_by(email: current_gestionnaire.email)

      if administrateur
        sign_in administrateur
      end
    end
  end
end
