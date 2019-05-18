class Users::PasswordsController < Devise::PasswordsController
  after_action :try_to_authenticate_gestionnaire, only: [:update]
  after_action :try_to_authenticate_administrateur, only: [:update]

  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  def create
    # Check the credentials associated to the mail to generate a correct reset link
    email = params[:user][:email]
    if Administrateur.find_by(email: email)
      @devise_mapping = Devise.mappings[:administrateur]
      params[:administrateur] = params[:user]
    elsif Gestionnaire.find_by(email: email)
      @devise_mapping = Devise.mappings[:gestionnaire]
      params[:gestionnaire] = params[:user]
    end
    super
  end

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

  def test_strength
    @score, @words, @length = ZxcvbnService.new(password_params[:password]).complexity
    @min_length = PASSWORD_MIN_LENGTH
    @min_complexity = PASSWORD_COMPLEXITY_FOR_USER
    render 'shared/password/test_strength'
  end

  def password_params
    params.require(:user).permit(:reset_password_token, :password)
  end
end
