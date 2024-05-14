# frozen_string_literal: true

module Administrateurs
  class APITokensController < AdministrateurController
    include ActionView::RecordIdentifier

    before_action :authenticate_administrateur!
    before_action :set_api_token, only: [:edit, :update, :destroy]

    def nom
      @name = name
    end

    def autorisations
      @name = name
      @libelle_id_procedures = current_administrateur
        .procedures
        .order(:libelle)
        .pluck(:libelle, :id)
        .map { |libelle, id| ["#{id} - #{libelle}", id] }
    end

    def securite
    end

    def create
      if params[:networkFiltering] == "customNetworks" && invalid_network?
        return redirect_to securite_admin_api_tokens_path(all_params.merge(invalidNetwork: true))
      end

      @api_token, @packed_token = APIToken.generate(current_administrateur)

      @api_token.update!(name:, write_access:,
                         allowed_procedure_ids:, authorized_networks:, expires_at:)

      @curl_command = curl_command(@packed_token, @api_token.procedure_ids.first)
    end

    def edit
    end

    def update
      if invalid_network?
        @invalid_network = true
        return render :edit
      end

      if @api_token.eternal? && networks.empty?
        flash[:alert] = "Vous ne pouvez pas supprimer les restrictions d'accès à l'API d'un jeton permanent."
        return render :edit
      end

      @api_token.update!(name:, authorized_networks: networks)

      flash[:notice] = "Le jeton d'API a été mis à jour."
      redirect_to profil_path
    end

    def destroy
      @api_token.destroy

      render turbo_stream: turbo_stream.remove(dom_id(@api_token))
    end

    private

    def curl_command(packed_token, procedure_id)
      <<~EOF
        curl \\
        -H 'Content-Type: application/json' \\
        -H 'Authorization: Bearer #{packed_token}' \\
        --data '{ "query": "{ demarche(number: #{procedure_id}) { title } }" }' \\
        '#{api_v2_graphql_url}'
      EOF
    end

    def all_params
      [:name, :access, :target, :targets, :networkFiltering, :networks, :lifetime, :customLifetime]
        .index_with { |param| params[param] }
    end

    def authorized_networks
      if params[:networkFiltering] == "customNetworks"
        networks
      else
        []
      end
    end

    def invalid_network?
      params[:networks]
        .split
        .any? do
          begin
            IPAddr.new(_1)
            false
          rescue
            true
          end
        end
    end

    def networks
      params[:networks]
        .split
        .map { begin IPAddr.new(_1) rescue nil end }
        .compact
    end

    def set_api_token
      @api_token = current_administrateur.api_tokens.find(params[:id])
    end

    def name
      params[:name]
    end

    def write_access
      params[:access] == "read_write"
    end

    def allowed_procedure_ids
      if params[:target] == "custom"
        current_administrateur
          .procedure_ids
          .intersection(params[:targets].map(&:to_i))
      else
        nil
      end
    end

    def expires_at
      case params[:lifetime]
      in 'oneWeek'
        1.week.from_now.to_date
      in 'custom'
        [
          Date.parse(params[:customLifetime]),
          1.year.from_now
        ].min
      in 'infinite' if authorized_networks.present?
        nil
      else
        1.week.from_now.to_date
      end
    end
  end
end
