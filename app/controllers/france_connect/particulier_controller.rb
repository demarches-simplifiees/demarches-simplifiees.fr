class FranceConnect::ParticulierController < ApplicationController
  before_action :redirect_to_login_if_fc_aborted, only: [:callback]

  def login
    redirect_to FranceConnectService.authorization_uri
  end

  def callback
    fetched_fci = FranceConnectService.retrieve_user_informations_particulier(params[:code])

    fci = FranceConnectInformation
      .find_by(france_connect_particulier_id: fetched_fci[:france_connect_particulier_id]) ||
        fetched_fci.tap { |object| object.save }

    if fci.user.nil?
      user = User.find_or_create_by(email: fci.email_france_connect) do |new_user|
        new_user.password = Devise.friendly_token[0, 20]
        new_user.confirmed_at = DateTime.now
      end

      fci.update_attribute('user_id', user.id)
    end

    connect_france_connect_particulier(fci.user)
  rescue Rack::OAuth2::Client::Error => e
    Rails.logger.error e.message
    redirect_france_connect_error_connection
  end

  private

  def redirect_to_login_if_fc_aborted
    if params[:code].empty?
      redirect_to new_user_session_path
    end
  end

  def connect_france_connect_particulier(user)
    sign_out :user if user_signed_in?
    sign_out :gestionnaire if gestionnaire_signed_in?
    sign_out :administrateur if administrateur_signed_in?

    sign_in user

    user.update_attribute('loged_in_with_france_connect', 'particulier')

    redirect_to stored_location_for(current_user) || root_path(current_user)
  end

  def redirect_france_connect_error_connection
    flash.alert = t('errors.messages.france_connect.connexion')
    redirect_to(new_user_session_path)
  end
end
