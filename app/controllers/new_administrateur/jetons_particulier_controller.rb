# frozen_string_literal: true

module NewAdministrateur
  class JetonsParticulierController < AdministrateurController
    before_action :retrieve_procedure, only: [:index, :jeton, :update_jeton, :sources, :update_sources]

    def index
    end

    def jeton
    end

    def update_jeton
      token = update_jeton_params[:api_particulier_token]
      @procedure.api_particulier_token = token

      if @procedure.valid? && fetch_scopes(token).any?
        @procedure.api_particulier_scopes = fetch_scopes(token)
        @procedure.api_particulier_sources = nil
        @procedure.save

        redirect_to admin_procedure_jetons_particulier_path(procedure_id: params[:procedure_id]),
          notice: "Le jeton a bien été mis à jour"
      else
        flash.now.alert = "Mise à jour impossible : le jeton n'est pas valide"
        render :jeton
      end
    end

    def sources
      if @procedure.api_particulier_scopes.blank?
        flash.now.alert = "Veuillez renseignez un jeton API particulier valide pour définir les sources de données"
        render :index
      else
        @procedure_sources = @procedure.api_particulier_sources.presence
        @procedure_sources ||= APIParticulier::Services::BuildProcedureMask.new(@procedure).call

        @check_scope_sources_service = APIParticulier::Services::CheckScopeSources.new(
          @procedure.api_particulier_scopes,
          @procedure.api_particulier_sources
        )
      end
    end

    def update_sources
      @procedure.api_particulier_sources = update_sources_hash

      if update_sources_hash.any? && @procedure.valid?
        @procedure.save

        redirect_to admin_procedure_jetons_particulier_path(procedure_id: params[:procedure_id]),
          notice: "Les sources de données ont bien été mises à jour"
      else
        flash.now.alert = "Mise à jour impossible : les sources de données ne sont pas valides"
        render :sources
      end
    end

    private

    def fetch_scopes(token)
      return [] if token.blank?

      @fetch_scopes ||= {}
      @fetch_scopes[token] ||= APIParticulier::API.new(token: token).introspect.scopes
    rescue APIParticulier::Error::HttpError
      []
    end

    def update_jeton_params
      params.require(:procedure).permit(:api_particulier_token)
    rescue ActionController::ParameterMissing
      ActionController::Parameters.new.permit
    end

    def update_sources_params
      params.require(:procedure).permit(dgfip: {}, caf: {}, pole_emploi: {}, mesri: {})
    rescue ActionController::ParameterMissing
      ActionController::Parameters.new.permit
    end

    def update_sources_hash
      @update_sources_hash ||= update_sources_params.to_h.deep_transform_values(&:to_i)
    end
  end
end
