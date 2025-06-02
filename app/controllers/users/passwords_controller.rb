# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  include DevisePopulatedResource

  after_action :try_to_authenticate_instructeur, only: [:update]
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
  #   @user = User.with_reset_password_token(params[:reset_password_token])
  #   super
  # end

  # PUT /resource/password
  # def update
  #   params[:user][:password_confirmation] = params[:user][:password]
  # super
  # end

  def reset_link_sent
    @email = message_verifier.verify(params[:email], purpose: :reset_password) rescue nil
  end

  protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  def after_sending_reset_password_instructions_path_for(resource_name)
    flash.discard(:notice)
    signed_email = message_verifier.generate(resource.email, purpose: :reset_password, expires_in: 1.hour)
    users_password_reset_link_sent_path(email: signed_email)
  end

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
end
