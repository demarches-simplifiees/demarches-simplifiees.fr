class FranceConnect::ParticulierController < ApplicationController
  before_action :redirect_to_login_if_fc_aborted, only: [:callback]

  def login
    if FranceConnectService.enabled?
      redirect_to FranceConnectService.authorization_uri
    else
      redirect_to new_user_session_path
    end
  end

  def callback
    fetched_fci = FranceConnectService.retrieve_user_informations_particulier(params[:code])
    fci = FranceConnectInformation.find_by(france_connect_particulier_id: fetched_fci[:france_connect_particulier_id]) || fetched_fci
    user = fci.user || User.find_by(email: fci.email_france_connect.downcase)

    if user.nil? || user.can_france_connect?
      fci.user = User.find_or_create_by!(email: fci.email_france_connect.downcase) do |new_user|
        new_user.password = Devise.friendly_token[0, 20]
        new_user.confirmed_at = Time.zone.now
      end
      fci.save!

      connect_france_connect_particulier(fci.user)
    else
      if fci.presisted?
        fci.destroy
      end

      redirect_france_connect_error_connection
    end
  rescue Rack::OAuth2::Client::Error => e
    Rails.logger.error e.message
    redirect_france_connect_error_connection
  end

  private

  def redirect_to_login_if_fc_aborted
    if params[:code].blank?
      redirect_to new_user_session_path
    end
  end

  def connect_france_connect_particulier(user)
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

    user.update_attribute('loged_in_with_france_connect', User.loged_in_with_france_connects.fetch(:particulier))

    redirect_to stored_location_for(current_user) || root_path(current_user)
  end

  def redirect_france_connect_error_connection
    flash.alert = t('errors.messages.france_connect.connexion')
    redirect_to(new_user_session_path)
  end
end
