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

    salt = FranceConnectSaltService.new(fci).salt

    if fci.user.nil?
      redirect_to france_connect_particulier_new_path(fci_id: fci.id, salt: salt)
    else
      connect_france_connect_particulier(fci.user)
    end
  rescue Rack::OAuth2::Client::Error => e
    Rails.logger.error e.message
    redirect_france_connect_error_connection
  end

  def new
    return redirect_france_connect_error_connection if !valid_salt_and_fci_id_params?

    france_connect_information = FranceConnectInformation.find(params[:fci_id])
    @user = User.new(france_connect_information: france_connect_information).decorate
  rescue ActiveRecord::RecordNotFound
    redirect_france_connect_error_connection
  end

  def check_email
    return redirect_france_connect_error_connection if !valid_salt_and_fci_id_params?

    user = User.find_by_email(params[:user][:email_france_connect])

    return create if user.nil?

    if params[:user][:password].present?

      if user.valid_password?(params[:user][:password])
        user.france_connect_information = FranceConnectInformation.find(params[:fci_id])

        return connect_france_connect_particulier user
      else
        flash.now.alert = 'Mot de passe invalide'
      end
    end

    france_connect_information = FranceConnectInformation.find(params[:fci_id])
    france_connect_information.update_attribute(:email_france_connect, params[:user][:email_france_connect])

    @user = User.new(france_connect_information: france_connect_information).decorate
  end

  private

  def redirect_to_login_if_fc_aborted
    if params[:code].nil?
      redirect_to new_user_session_path
    end
  end

  def create
    user = User.new email: params[:user][:email_france_connect]
    user.password = Devise.friendly_token[0, 20]

    if !user.valid?
      flash.alert = 'Email non valide'

      return redirect_to france_connect_particulier_new_path fci_id: params[:fci_id], salt: params[:salt], user: {email_france_connect: params[:user]['email_france_connect']}
    end

    user.save
    FranceConnectInformation.find(params[:fci_id]).update_attribute(:user, user)

    connect_france_connect_particulier user
  end

  def connect_france_connect_particulier user
    sign_out :user if user_signed_in?
    sign_out :gestionnaire if gestionnaire_signed_in?
    sign_out :administrateur if administrateur_signed_in?

    sign_in user

    user.loged_in_with_france_connect = 'particulier'
    user.save

    redirect_to stored_location_for(current_user) || signed_in_root_path(current_user)
  end

  def redirect_france_connect_error_connection
    flash.alert = t('errors.messages.france_connect.connexion')
    redirect_to(new_user_session_path)
  end

  def valid_salt_and_fci_id_params?
    france_connect_information = FranceConnectInformation.find(params[:fci_id])
    FranceConnectSaltService.new(france_connect_information).valid? params[:salt]
  end
end
