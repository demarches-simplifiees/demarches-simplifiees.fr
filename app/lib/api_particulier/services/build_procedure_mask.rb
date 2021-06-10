# frozen_string_literal: true

module APIParticulier
  module Services
    class BuildProcedureMask
      def initialize(procedure, **kwargs)
        deps = kwargs.symbolize_keys
        @check_scope_sources_service = deps[:check_scope_sources_service]
        @procedure = procedure
      end

      def call
        {
          caf: caf
        }.deep_symbolize_keys
      end

      private

      attr_reader :procedure

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
        }.compact.merge(caf_quotient_familial)
      end

      def caf_allocataires
        return unless check_scope_sources_service.mandatory?("cnaf_allocataires", strict: false)

        APIParticulier::Entities::CAF::Personne.new.as_json
      end

      def caf_enfants
        return unless check_scope_sources_service.mandatory?("cnaf_enfants", strict: false)

        APIParticulier::Entities::CAF::Personne.new.as_json
      end

      def caf_adresse
        return unless check_scope_sources_service.mandatory?("cnaf_adresse", strict: false)

        APIParticulier::Entities::CAF::PosteAdresse.new.as_json
      end

      def caf_quotient_familial
        return {} unless check_scope_sources_service.mandatory?("cnaf_quotient_familial", strict: false)

        APIParticulier::Entities::CAF::QuotientFamilial.new.as_json
      end
    end
  end
end
