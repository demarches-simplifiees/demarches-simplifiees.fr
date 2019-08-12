class Sessions::SessionsController < Devise::SessionsController
  before_action :before_sign_in, only: [:create]

  layout 'new_application'

  def before_sign_in
    if user_signed_in?
      sign_out :user
    end

    if instructeur_signed_in?
      sign_out :instructeur
    end

    if administrateur_signed_in?
      sign_out :administrateur
    end

    if administration_signed_in?
      sign_out :administration
    end
  end
end
