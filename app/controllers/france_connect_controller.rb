class FranceConnectController < ApplicationController
  def login
    client = FranceConnectClient.new

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
    user_infos = FranceConnectService.retrieve_user_informations(params[:code])

    unless user_infos.nil?
      @user = User.find_for_france_connect(user_infos.email)

      sign_in @user

      redirect_to(controller: 'users/dossiers', action: :index)
    end
  end
end