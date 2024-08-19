# frozen_string_literal: true

module Maintenance
  class PopulateRNAJSONValueTask < MaintenanceTasks::Task
    def collection
      Champs::RNAChamp.where.not(value: nil)
    end

    def process(champ)
      return if champ&.dossier&.procedure&.id.blank?
      data = APIEntreprise::RNAAdapter.new(champ.value, champ&.dossier&.procedure&.id).to_params
      return if data.blank?
      champ.update(value_json: APIGeoService.parse_rna_address(data['adresse']))
    end

    def count
      # not really interested in counting because it raises PG Statement timeout
    end
  end
end
