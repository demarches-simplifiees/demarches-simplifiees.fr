class Administrateurs::PasswordsController < Devise::PasswordsController
  after_action :try_to_authenticate_user, only: [:update]
  after_action :try_to_authenticate_gestionnaire, only: [:update]

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
  #   # params[:user][:password_confirmation] = params[:user][:password]
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
    if administrateur_signed_in?
      user = User.find_by(email: current_administrateur.email)

      if user
        sign_in user
      end
    end
  end

  def try_to_authenticate_gestionnaire
    if administrateur_signed_in?
      gestionnaire = Gestionnaire.find_by(email: current_administrateur.email)

      if gestionnaire
        sign_in gestionnaire
      end
    end
  end

  def test_strength
    @score, @words, @length = ZxcvbnService.new(password_params[:password]).complexity
    @min_length = PASSWORD_MIN_LENGTH
    @min_complexity = PASSWORD_COMPLEXITY_FOR_ADMIN
    render 'shared/password/test_strength'
  end

  private

  def password_params
    params.require(:administrateur).permit(:reset_password_token, :password)
  end
end
