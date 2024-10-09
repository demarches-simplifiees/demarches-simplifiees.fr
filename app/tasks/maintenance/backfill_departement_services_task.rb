# frozen_string_literal: true

module Maintenance
  class BackfillDepartementServicesTask < MaintenanceTasks::Task
    # Fait le lien service – département pour permettre
    # le filtrage des démarches par département
    # 2023-10-30-01 PR #9647
    def collection
      Service.where.not(etablissement_infos: nil)
    end

    def process(service)
      code_insee_localite = service.etablissement_infos['code_insee_localite']
      if code_insee_localite.present?
        departement = CodeInsee.new(code_insee_localite).to_departement
        service.update!(departement: departement)
      end
    end

    def count
      collection.count
    end
  end
end
