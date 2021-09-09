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
          notice: t('.token_ok')
      else
        flash.now.alert = t('.invalid_token')
        render :show
      end
    rescue APIParticulier::Error::Unauthorized
      flash.now.alert = t('.not_found_token')
      render :show
    rescue APIParticulier::Error::HttpError
      flash.now.alert = t('.network_error')
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
