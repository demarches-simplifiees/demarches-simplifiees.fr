# frozen_string_literal: true

module APIParticulier
  module Services
    class SanitizeData
      def call(data, mask)
        {
          dgfip: dgfip(data, mask),
          caf: caf(data, mask),
          pole_emploi: pole_emploi(data, mask),
          mesri: mesri(data, mask)
        }
      end

      private

      def dgfip(data, mask)
        {
          avis_imposition: dgfip_avis_imposition(data, mask).presence,
          foyer_fiscal: dgfip_foyer_fiscal(data, mask).presence
        }.compact
      end

      def dgfip_avis_imposition(data, mask)
        avis_imposition_data = data.dig(:dgfip, :avis_imposition)
        return if avis_imposition_data.nil?

        avis_imposition_mask = Hash(mask.dig(:dgfip, :avis_imposition))

        avis_imposition_data.as_sanitized_json(avis_imposition_mask).tap do |avis|
          avis.delete(:declarant1) if avis[:declarant1].blank?
          avis.delete(:declarant2) if avis[:declarant2].blank?
          avis.delete(:foyer_fiscal)
        end
      end

      def dgfip_foyer_fiscal(data, mask)
        foyer_fiscal_data = data.dig(:dgfip, :foyer_fiscal)
        return if foyer_fiscal_data.nil?

        foyer_fiscal_mask = Hash(mask.dig(:dgfip, :foyer_fiscal))
        foyer_fiscal_data.as_sanitized_json(foyer_fiscal_mask)
      end

      def caf(data, mask)
        {
          allocataires: caf_allocataires(data, mask).presence,
          enfants: caf_enfants(data, mask).presence,
          adresse: caf_adresse(data, mask).presence
        }.merge(caf_quotient_familial(data, mask)).compact
      end

      def caf_allocataires(data, mask)
        allocataires_data = data.dig(:caf, :allocataires)
        return if allocataires_data.nil?

        allocataires_mask = Hash(mask.dig(:caf, :allocataires))
        allocataires_data.filter_map { |a| a.as_sanitized_json(allocataires_mask).presence }
      end

      def caf_enfants(data, mask)
        enfants_data = data.dig(:caf, :enfants)
        return if enfants_data.nil?

        enfants_mask = Hash(mask.dig(:caf, :enfants))
        enfants_data.filter_map { |e| e.as_sanitized_json(enfants_mask).presence }
      end

      def caf_adresse(data, mask)
        adresse_data = data.dig(:caf, :adresse)
        return if adresse_data.nil?

        adresse_mask = Hash(mask.dig(:caf, :adresse))
        adresse_data.as_sanitized_json(adresse_mask)
      end

      def caf_quotient_familial(data, mask)
        data.fetch(:caf, {}).slice(:quotient_familial, :annee, :mois).reject do |k, _|
          mask.dig(:caf, k).to_i == 0
        end
      end

      def pole_emploi(data, mask)
        { situation: pole_emploi_situation(data, mask).presence }.compact
      end

      def pole_emploi_situation(data, mask)
        situation_data = data.dig(:pole_emploi, :situation)
        return if situation_data.nil?

        situation_mask = Hash(mask.dig(:pole_emploi, :situation))
        situation_data.as_sanitized_json(situation_mask)
      end

      def mesri(data, mask)
        { statut_etudiant: mesri_statut_etudiant(data, mask).presence }.compact
      end

      def mesri_statut_etudiant(data, mask)
        statut_etudiant_data = data.dig(:mesri, :statut_etudiant)
        return if statut_etudiant_data.nil?

        statut_etudiant_mask = Hash(mask.dig(:mesri, :statut_etudiant))
        statut_etudiant_data.as_sanitized_json(statut_etudiant_mask)
      end
    end
  end
end
