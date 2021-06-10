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
          dgfip: dgfip,
          caf: caf,
          pole_emploi: pole_emploi,
          mesri: mesri
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

      def dgfip
        {
          avis_imposition: dgfip_avis_imposition,
          foyer_fiscal: dgfip_foyer_fiscal
        }.compact
      end

      def dgfip_avis_imposition
        return unless check_scope_sources_service.mandatory?("dgfip_avis_imposition", strict: false)

        APIParticulier::Entities::DGFIP::AvisImposition.new.as_json.tap do |avis|
          avis["declarant1"] ||= APIParticulier::Entities::DGFIP::Declarant.new.as_json
          avis["declarant2"] ||= APIParticulier::Entities::DGFIP::Declarant.new.as_json
          avis.delete("foyer_fiscal")
        end
      end

      def dgfip_foyer_fiscal
        return unless check_scope_sources_service.mandatory?("dgfip_adresse", strict: false)

        APIParticulier::Entities::DGFIP::FoyerFiscal.new.as_json
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

      def pole_emploi
        { situation: pole_emploi_situation }.compact
      end

      def pole_emploi_situation
        return unless check_scope_sources_service.mandatory?("pe_situation_individu", strict: false)

        APIParticulier::Entities::PoleEmploi::SituationPoleEmploi.new.as_json.tap do |situation|
          situation["adresse"] ||= APIParticulier::Entities::PoleEmploi::Adresse.new.as_json
        end
      end

      def mesri
        { statut_etudiant: mesri_statut_etudiant }.compact
      end

      def mesri_statut_etudiant
        return unless check_scope_sources_service.mandatory?("mesri_statut_etudiant", strict: false)

        APIParticulier::Entities::MESRI::Etudiant.new.as_json.tap do |etudiant|
          etudiant["inscriptions"] = APIParticulier::Entities::MESRI::Inscription.new.as_json.tap do |insc|
            insc["etablissement"] ||= APIParticulier::Entities::MESRI::Etablissement.new.as_json
          end
        end
      end
    end
  end
end
