class FranceConnect::ParticulierController < ApplicationController
  def login
    client = FranceConnectParticulierClient.new

    session[:state] = SecureRandom.hex(16)
    session[:nonce] = SecureRandom.hex(16)

    authorization_uri = client.authorization_uri(
        scope: [:profile, :email],
        state: session[:state],
        nonce: session[:nonce]
    )
    redirect_to authorization_uri
  end

  def new
    return redirect_to root_path if france_connect_particulier_id_blank?

    @user = (User.new create_user_params).decorate
  end

  def create
    user = User.new create_user_params
    user.password = Devise.friendly_token[0, 20]

    unless user.valid?
      flash.alert = 'Email non valide'
      return redirect_to france_connect_particulier_new_path user: params[:user]
    end

    user.save
    connect_france_connect_particulier user
  end

  def check_email
    user = User.find_by_email(params[:user][:email])

    return create if user.nil?
    return redirect_to root_path if france_connect_particulier_id_blank?

    unless params[:user][:password].nil?

      if user.valid_password?(params[:user][:password])
        user.update_attributes create_user_params
        return connect_france_connect_particulier user
      else
        flash.now.alert = 'Mot de passe invalide'
      end
    end

    @user = (User.new create_user_params).decorate
  end

  def callback
    return redirect_to new_user_session_path unless params.has_key?(:code)

    user_infos = FranceConnectService.retrieve_user_informations_particulier(params[:code])

    unless user_infos.nil?
      user = User.find_for_france_connect_particulier user_infos

      if user.nil?
        return redirect_to france_connect_particulier_new_path(user: user_infos)
      end

      connect_france_connect_particulier user
    end
  rescue Rack::OAuth2::Client::Error => e
    Rails.logger.error e.message
    flash.alert = t('errors.messages.france_connect.connexion')
    redirect_to(new_user_session_path)
  end

  private

  def create_user_params
    params.require(:user).permit(:france_connect_particulier_id, :gender, :given_name, :family_name, :birthdate, :birthplace, :email)
  end

  def france_connect_particulier_id_blank?
    redirect_to root_path if params[:user][:france_connect_particulier_id].blank?
  end

  def connect_france_connect_particulier user
    sign_in user

    user.loged_in_with_france_connect = 'particulier'
    user.save

    redirect_to stored_location_for(current_user) || signed_in_root_path(current_user)
  end
end