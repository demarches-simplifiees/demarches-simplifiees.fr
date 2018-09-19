class Users::RegistrationsController < Devise::RegistrationsController
  layout "new_application"

  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # def after_sign_up_path_for(resource_or_scope)
  #   super
  # end

  # GET /resource/sign_up
  def new
    # Allow pre-filling the user email from a query parameter
    build_resource({ email: sign_up_params[:email] })

    yield resource if block_given?
    respond_with resource
  end

  # POST /resource
  def create
    user = User.find_by(email: params[:user][:email])
    if user.present?
      if user.confirmed?
        UserMailer.new_account_warning(user).deliver_later
      else
        user.resend_confirmation_instructions
      end
      flash.notice = t('devise.registrations.signed_up_but_unconfirmed')
      redirect_to root_path
    else
      super
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
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
