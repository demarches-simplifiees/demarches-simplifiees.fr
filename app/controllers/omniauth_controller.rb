class OmniauthController < ApplicationController
  before_action :redirect_to_login_if_connection_aborted, only: [:callback]

  PROVIDERS = ['google', 'microsoft', 'yahoo', 'sipf', 'tatou']

  def login
    provider = params[:provider]
    # already checked in routes.rb but brakeman complains
    if PROVIDERS.include?(provider)
      redirect_to OmniAuthService.authorization_uri(provider)
    else
      raise "Invalid authentication method '#{provider} (should be any of #{PROVIDERS})"
    end
  end

  def callback
    provider = params[:provider]
    fci = OmniAuthService.find_or_retrieve_user_informations(provider, params[:code])
    fci.associate_user!

    if fci.user && !fci.user.can_france_connect?
      fci.destroy
      redirect_to new_user_session_path, alert: t('errors.messages.omni_auth.forbidden_html', reset_link: new_user_password_path, provider: t("errors.messages.omni_auth.#{provider}"))
      return
    end

    connect(provider, fci.user)
  rescue Rack::OAuth2::Client::Error => e
    Rails.logger.error e.message
    redirect_error_connection(provider)
  end

  private

  def redirect_to_login_if_connection_aborted
    if params[:code].blank?
      redirect_to new_user_session_path
    end
  end

  def connect(provider, user)
    if user_signed_in?
      sign_out :user
    end

    if instructeur_signed_in?
      sign_out :instructeur
    end

    if administrateur_signed_in?
      sign_out :administrateur
    end

    sign_in user

    user.update_attribute('loged_in_with_france_connect', User.loged_in_with_france_connects.fetch(provider))

    redirect_to stored_location_for(current_user) || root_path(current_user)
  end

  def redirect_error_connection(provider)
    flash.alert = t("errors.messages.omni_auth.connexion", provider: t("errors.messages.omni_auth.#{provider}"))
    redirect_to(new_user_session_path)
  end
end
