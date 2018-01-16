class Administrations::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    administration = Administration.from_omniauth(request.env["omniauth.auth"])
    if administration.present?
      sign_in administration
      redirect_to manager_administrateurs_path
    else
      flash[:alert] = "Compte GitHub non autorisé"
      redirect_to root_path
    end
  end

  def failure
    redirect_to root_path
  end
end
