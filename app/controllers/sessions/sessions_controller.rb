class Sessions::SessionsController < Devise::SessionsController
  before_action :before_sign_in, only: [:create]

  def before_sign_in
    if user_signed_in?
      sign_out :user
    end

    if gestionnaire_signed_in?
      sign_out :gestionnaire
    end

    if administrateur_signed_in?
      sign_out :administrateur
    end

    if administration_signed_in?
      sign_out :administration
    end
  end
end
