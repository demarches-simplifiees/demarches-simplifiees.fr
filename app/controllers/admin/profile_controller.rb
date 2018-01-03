class Admin::ProfileController < AdminController
  def show
    @administrateur = current_administrateur
  end

  def renew_api_token
    flash[:notice] = "Votre token d'API a été regénéré."
    current_administrateur.renew_api_token
    redirect_to admin_profile_path
  end
end
