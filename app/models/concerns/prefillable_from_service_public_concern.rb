# frozen_string_literal: true

module PrefillableFromServicePublicConcern
  extend ActiveSupport::Concern

  included do
    def prefill_from_siret
      result = AnnuaireServicePublicService.new.(siret:)
      # TODO: get organisme, … from API Entreprise
      case result
      in Dry::Monads::Success(data)
        self.nom = data[:nom] if nom.blank?
        self.email = data[:adresse_courriel] if email.blank?
        self.telephone = data[:telephone]&.first&.dig("valeur") if telephone.blank?
        self.horaires = denormalize_plage_ouverture(data[:plage_ouverture]) if horaires.blank?
        self.adresse = APIGeoService.inline_service_public_address(data[:adresse]&.first) if adresse.blank?
      else
        # NOOP
      end

      result
    end

    private

    def denormalize_plage_ouverture(data)
      return if data.blank?

      data.map do |range|
        day_range = range.values_at('nom_jour_debut', 'nom_jour_fin').uniq.join(' au ')

        hours_range = (1..2).each_with_object([]) do |i, hours|
          start_hour = range["valeur_heure_debut_#{i}"]
          end_hour = range["valeur_heure_fin_#{i}"]

          if start_hour.present? && end_hour.present?
            hours << "de #{format_time(start_hour)} à #{format_time(end_hour)}"
          end
        end

        result = day_range
        result += " : #{hours_range.join(' et ')}" if hours_range.present?
        result += " (#{range['commentaire']})" if range['commentaire'].present?
        result
      end.join("\n")
    end

    def format_time(str_time)
      Time.zone
        .parse(str_time)
        .strftime("%-H:%M")
    end
  end
end
