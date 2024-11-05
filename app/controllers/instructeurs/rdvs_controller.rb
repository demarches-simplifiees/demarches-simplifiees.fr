# frozen_string_literal: true

module Instructeurs
  class RdvsController < InstructeurController
    before_action :set_dossier

    def connect
      auth_url = "#{API_RDV_URL}/oauth/authorize?" + {
        client_id: Rails.application.secrets.dig(:rdv_service_public, :client_id),
        redirect_uri: Rails.application.secrets.dig(:rdv_service_public, :redirect_uri),
        response_type: "code",
        scope: "required_scopes"
      }.to_query

      redirect_to auth_url
    end

    def callback
      # Exchange authorization code for access token
      response = HTTP.post("#{API_RDV_URL}/oauth/token", form: {
        client_id: Rails.application.secrets.dig(:rdv_service_public, :client_id),
        client_secret: Rails.application.secrets.dig(:rdv_service_public, :client_secret),
        code: params[:code],
        grant_type: "authorization_code",
        redirect_uri: Rails.application.secrets.dig(:rdv_service_public, :redirect_uri)
      })

      token_data = JSON.parse(response.body)

      # Store the connection
      current_user.create_rdv_connection!(
        access_token: token_data["access_token"],
        refresh_token: token_data["refresh_token"],
        expires_at: Time.current + token_data["expires_in"].seconds
      )

      redirect_to rdv_success_path, notice: "Connection à RDV Service Public réussie"
    end

    def create
      @rdv = RdvService.new.create_rdv(dossier: @dossier)
    end

    private

    def set_dossier
      @dossier = current_instructeur.dossiers.find(params[:dossier_id])
    end
  end
end
