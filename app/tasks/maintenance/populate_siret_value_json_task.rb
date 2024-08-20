# frozen_string_literal: true

module Maintenance
  class PopulateSiretValueJSONTask < MaintenanceTasks::Task
    def collection
      Champs::SiretChamp.where.not(value: nil)
    end

    def process(champ)
      return if champ.etablissement.blank?
      champ.update!(value_json: APIGeoService.parse_etablissement_address(champ.etablissement))
    end

    def count
      # not really interested in counting because it raises PG Statement timeout
    end
  end
end
