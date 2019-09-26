class Users::RegistrationsController < Devise::RegistrationsController
  include ProcedureContextConcern

  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]
  before_action :restore_procedure_context, only: [:new, :create]

  layout 'procedure_context', only: [:new, :create]

  # GET /resource/sign_up
  def new
    # Allow pre-filling the user email from a query parameter
    build_resource({ email: sign_up_params[:email] })

    if block_given?
      yield resource
    end

    respond_with resource
  end

  # POST /resource
  def create
    existing_user = User.find_by(email: params[:user][:email])
    if existing_user.present?
      handle_existing_user(existing_user) and return
    end

    super
  end

  def handle_existing_user(user)
    if user.confirmed? && user.valid_password?(params[:user][:password])
      sign_in(user)
      flash.notice = t('devise.sessions.signed_in')
      respond_with user, location: after_sign_in_path_for(user)
    elsif user.confirmed?
      UserMailer.new_account_warning(user).deliver_later
      redirect_to after_inactive_sign_up_path_for(user)
    else
      user.resend_confirmation_instructions
      redirect_to after_inactive_sign_up_path_for(user)
    end
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # You can put the params you want to permit in the empty array.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.for(:sign_up) << :attribute
  # end

  # You can put the params you want to permit in the empty array.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.for(:account_update) << :attribute
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    flash.discard(:notice) # Remove devise's default message (as we have a custom page to explain it)
    new_confirmation_path(resource, :user => { email: resource.email })
  end
end
