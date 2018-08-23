module NewAdministrateur
  class ProfilController < AdministrateurController
    def show
      @administrateur = current_administrateur
    end

    def renew_api_token
      flash[:notice] = "Votre token d'API a été regénéré."
      current_administrateur.renew_api_token
      redirect_to profil_path
    end
  end
end
