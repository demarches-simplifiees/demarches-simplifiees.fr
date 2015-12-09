class Sessions::SessionsController < Devise::SessionsController

  before_action :before_sign_in, only: [:create]

  def before_sign_in
    sign_out :user if user_signed_in?
    sign_out :gestionnaire if gestionnaire_signed_in?
    sign_out :administrateur if administrateur_signed_in?
  end
end
