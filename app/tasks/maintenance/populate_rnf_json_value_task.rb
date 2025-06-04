# frozen_string_literal: true

# Dans le cadre de la story pour pouvoir rechercher un dossier en fonction des valeurs des champs branchées sur une API, voici une première pièce qui cible les champs RNA/RNF/SIRET (notamment les adresses pour de la recherche). Cette PR intègre :
#     la normalisation des adresses des champs RNA/RNF/SIRET
#     le fait de stocker ces données normalisées dans le champs.value_json (un jsonb)
#     le backfill les anciens champs RNA/RNF/SIRET
module Maintenance
  class PopulateRNFJSONValueTask < MaintenanceTasks::Task
    include Dry::Monads[:result]

    def collection
      Champs::RNFChamp.where("external_id != null and data != null") # had been found
      # Collection to be iterated over
      # Must be Active Record Relation or Array
    end

    def process(champ)
      result = champ.fetch_external_data
      case result
      in Success(data)
        begin
          champ.update_with_external_data!(data:)
        rescue ActiveRecord::RecordInvalid
          # some champ might have dossier nil
        end
      else # fondation was removed, but we kept API data in data:, use it to restore stuff

        champ.update_with_external_data!(data: champ.data.with_indifferent_access)
      end
    end

    def count
      # not really interested in counting because it raises PG Statement timeout
    end
  end
end
