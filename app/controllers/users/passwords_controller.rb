class Users::PasswordsController < Devise::PasswordsController
  after_action :try_to_authenticate_instructeur, only: [:update]
  after_action :try_to_authenticate_administrateur, only: [:update]

  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  def create
    # Check the credentials associated to the mail to generate a correct reset link
    email = params[:user][:email]
    if Administrateur.by_email(email)
      @devise_mapping = Devise.mappings[:administrateur]
      params[:administrateur] = params[:user]
      # uncomment to check password complexity for Instructeur
      # elsif Instructeur.by_email(email)
      #   @devise_mapping = Devise.mappings[:instructeur]
      #   params[:instructeur] = params[:user]
    end
    super
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  def edit
    user = User.with_reset_password_token(params[:reset_password_token])

    if user&.administrateur
      complexity = PASSWORD_COMPLEXITY_FOR_ADMIN
    elsif user&.instructeur
      complexity = PASSWORD_COMPLEXITY_FOR_INSTRUCTEUR
    else
      complexity = PASSWORD_COMPLEXITY_FOR_USER
    end
    @test_password_strength = test_password_strength_path(complexity)
    super
  end

  # PUT /resource/password
  def update
    params[:user][:password_confirmation] = params[:user][:password]
    super
  end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  def try_to_authenticate_instructeur
    if user_signed_in?
      instructeur = Instructeur.by_email(current_user.email)

      if instructeur
        sign_in(instructeur.user)
      end
    end
  end

  def try_to_authenticate_administrateur
    if user_signed_in?
      administrateur = Administrateur.by_email(current_user.email)

      if administrateur
        sign_in(administrateur.user)
      end
    end
  end

  def test_strength
    p = params.include?(:administrateur) ? params[:administrateur] : params.require(:user)
    @score, @words, @length = ZxcvbnService.new(p[:password]).complexity
    @min_length = PASSWORD_MIN_LENGTH
    @min_complexity = params[:complexity].to_i # proper type is verified in toutes.rb
    render 'shared/password/test_strength'
  end
end
