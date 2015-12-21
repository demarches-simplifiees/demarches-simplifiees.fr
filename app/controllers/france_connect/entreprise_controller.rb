class FranceConnect::EntrepriseController < ApplicationController
  def login
    client = FranceConnectEntrepriseClient.new

    session[:state] = SecureRandom.hex(16)
    session[:nonce] = SecureRandom.hex(16)

    authorization_uri = client.authorization_uri(
      scope: [:profile, :email],
      state: session[:state],
      nonce: session[:nonce]
    )
    redirect_to authorization_uri
  end

  def callback
    return redirect_to new_user_session_path unless params.has_key?(:code)

    user_infos = FranceConnectService.retrieve_user_informations_entreprise(params[:code])

    unless user_infos.nil?
      @user = User.find_for_france_connect(user_infos.email, user_infos.siret)

      sign_in @user

      @user.loged_in_with_france_connect = true
      @user.save

      redirect_to stored_location_for(current_user) || signed_in_root_path(current_user)
    end
  rescue Rack::OAuth2::Client::Error => e
    Rails.logger.error e.message
    flash.alert = t('errors.messages.france_connect.connexion')
    redirect_to(new_user_session_path)
  end
end