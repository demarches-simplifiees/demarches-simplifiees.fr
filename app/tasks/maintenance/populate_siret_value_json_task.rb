# frozen_string_literal: true

# Dans le cadre de la story pour pouvoir rechercher un dossier en fonction des valeurs des champs branchées sur une API, voici une première pièce qui cible les champs RNA/RNF/SIRET (notamment les adresses pour de la recherche). Cette PR intègre :
#     la normalisation des adresses des champs RNA/RNF/SIRET
#     le fait de stocker ces données normalisées dans le champs.value_json (un jsonb)
#     le backfill les anciens champs RNA/RNF/SIRET
module Maintenance
  class PopulateSiretValueJSONTask < MaintenanceTasks::Task
    def collection
      Champs::SiretChamp.where.not(value: nil)
    end

    def process(champ)
      return if champ.etablissement.blank?
      champ.update!(value_json: APIGeoService.parse_etablissement_address(champ.etablissement))
    rescue ActiveRecord::RecordInvalid
      # noop, just a champ without dossier
    end

    def count
      # not really interested in counting because it raises PG Statement timeout
    end
  end
end
