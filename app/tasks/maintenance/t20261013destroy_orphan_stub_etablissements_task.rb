# frozen_string_literal: true

module Maintenance
  class T20261013destroyOrphanStubEtablissementsTask < MaintenanceTasks::Task
    def collection
      Etablissement
        .where(adresse: nil)
        .where.missing(:dossier, :champ_data)
    end

    def process(etablissement)
      etablissement.destroy!
    end
  end
end
