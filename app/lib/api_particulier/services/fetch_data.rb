# frozen_string_literal: true

module APIParticulier
  module Services
    class FetchData
      def initialize(dossier, **kwargs)
        deps = kwargs.symbolize_keys
        @api = deps[:api]
        @check_scope_sources_service = deps[:check_scope_sources_service]
        @dossier = dossier
      end

      def call
        {
          caf: caf
        }
      end

      private

      attr_reader :dossier

      def individual
        @individual ||= dossier.individual
      end

      def procedure
        @procedure ||= dossier.procedure
      end

      def api_particulier_token
        @api_particulier_token ||= procedure.api_particulier_token
      end

      def api
        @api || APIParticulier::API.new(token: api_particulier_token)
      end

      def check_scope_sources_service
        @check_scope_sources_service || APIParticulier::Services::CheckScopeSources.new(
          procedure.api_particulier_scopes,
          procedure.api_particulier_sources
        )
      end

      def caf
        {
          allocataires: caf_allocataires,
          enfants: caf_enfants,
          adresse: caf_adresse
        }.merge(caf_quotient_familial).compact
      end

      def fetch_caf
        @fetch_caf ||= api.composition_familiale(
          numero_d_allocataire: individual.api_particulier_caf_numero_d_allocataire,
          code_postal: individual.api_particulier_caf_code_postal
        )
      end

      def caf_allocataires
        return unless check_scope_sources_service.mandatory?("cnaf_allocataires")

        fetch_caf.allocataires
      end

      def caf_enfants
        return unless check_scope_sources_service.mandatory?("cnaf_enfants")

        fetch_caf.enfants
      end

      def caf_adresse
        return unless check_scope_sources_service.mandatory?("cnaf_adresse")

        fetch_caf.adresse
      end

      def caf_quotient_familial
        return {} unless check_scope_sources_service.mandatory?("cnaf_quotient_familial")

        fetch_caf.as_json.symbolize_keys.slice(:quotient_familial, :annee, :mois)
      end
    end
  end
end
