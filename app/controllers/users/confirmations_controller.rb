# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation/new
  def new
    # Allow displaying the user email in the message
    self.resource = resource_class.new(email: user_email_param)
  end

  # POST /resource/confirmation
  # def create
  #   super
  # end

  # GET /resource/confirmation?confirmation_token=abcdef
  # def show
  #   super
  # end

  # protected

  def user_email_param
    params.permit(user: :email).dig(:user, :email)
  end

  # The path used after resending confirmation instructions.
  # def after_resending_confirmation_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  # If the user clicks the confirmation link before the maximum delay,
  # they will be signed in directly.
  def sign_in_after_confirmation?(resource)
    # Avoid keeping auto-sign-in links in users inboxes for too long.
    # 95% of users confirm their account within two hours.
    auto_sign_in_timeout = 2.hours
    resource.confirmation_sent_at + auto_sign_in_timeout > Time.zone.now
  end

  # The path used after confirmation.
  def after_confirmation_path_for(resource_name, resource)
    if sign_in_after_confirmation?(resource)
      resource.remember_me = true
      sign_in(resource)
      resource.force_sync_credentials
      after_sign_in_path_for(resource_name)
    else
      super(resource_name, resource)
    end
  end
end
