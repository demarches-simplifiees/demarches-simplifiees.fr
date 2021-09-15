module NewAdministrateur
  class JetonParticulierController < AdministrateurController
    before_action :retrieve_procedure

    def api_particulier
    end

    def show
    end

    def update
      @procedure.api_particulier_token = token

      if @procedure.valid? && fetch_scopes(token).any?
        @procedure.save

        redirect_to admin_procedure_api_particulier_jeton_path(procedure_id: @procedure.id),
          notice: "Le jeton a bien été mis à jour"
      else
        flash.now.alert = "Mise à jour impossible : le jeton n'est pas valide<br /><br />Vérifier le auprès de <a href='https://datapass.api.gouv.fr/'>https://datapass.api.gouv.fr/</a>"
        render :show
      end
    rescue APIParticulier::Error::Unauthorized
      flash.now.alert = "Mise à jour impossible : le jeton n'a pas été trouvé ou n'est pas actif<br /><br />Vérifier le auprès de <a href='https://datapass.api.gouv.fr/'>https://datapass.api.gouv.fr/</a>"
      render :show
    rescue APIParticulier::Error::HttpError
      flash.now.alert = "Mise à jour impossible : une erreur réseau est survenue"
      render :show
    end

    private

    def fetch_scopes(token)
      @scopes ||= APIParticulier::API.new(token).scopes
    end

    def token
      params[:procedure][:api_particulier_token]
    end
  end
end
