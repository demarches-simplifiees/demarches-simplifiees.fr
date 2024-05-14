# frozen_string_literal: true

module Administrateurs
  class JetonParticulierController < AdministrateurController
    before_action :retrieve_procedure

    def api_particulier
    end

    def show
    end

    def update
      @procedure.api_particulier_token = token

      if @procedure.invalid?
        flash.now.alert = @procedure.errors.full_messages
        render :show
      elsif scopes.empty?
        flash.now.alert = t('.no_scopes_token')
        render :show
      else
        @procedure.update!(api_particulier_scopes: scopes, api_particulier_sources: {})

        redirect_to admin_procedure_api_particulier_sources_path(procedure_id: @procedure.id),
          notice: t('.token_ok')
      end

    rescue APIParticulier::Error::Unauthorized
      flash.now.alert = t('.not_found_token')
      render :show
    rescue APIParticulier::Error::HttpError
      flash.now.alert = t('.network_error')
      render :show
    end

    private

    def scopes
      @scopes ||= APIParticulier::API.new(token).scopes
    end

    def token
      params[:procedure][:api_particulier_token]
    end
  end
end
