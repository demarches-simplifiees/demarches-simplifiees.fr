# frozen_string_literal: true

module APIParticulier
  module Services
    class SanitizeData
      def call(data, mask)
        {
          caf: caf(data, mask)
        }
      end

      private

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
    end
  end
end
