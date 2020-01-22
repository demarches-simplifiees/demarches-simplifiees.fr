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
    fetched_fci = OmniAuthService.retrieve_user_informations(provider, params[:code])

    fci = FranceConnectInformation
      .find_by(france_connect_particulier_id: fetched_fci[:france_connect_particulier_id]) ||
        fetched_fci.tap(&:save)

    if fci.user.nil?
      user = User.find_or_create_by!(email: fci.email_france_connect.downcase) do |new_user|
        new_user.password = Devise.friendly_token[0, 20]
        new_user.confirmed_at = Time.zone.now
      end

      fci.update_attribute('user_id', user.id)
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
    flash.alert = t("errors.messages.#{provider}.connexion")
    redirect_to(new_user_session_path)
  end
end
