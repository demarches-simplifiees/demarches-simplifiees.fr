# frozen_string_literal: true

module Maintenance
  class AddDossiersMissingChampsTask < MaintenanceTasks::Task
    csv_collection

    def process(row)
      DataFixer::DossierChampsMissing.new(dossier: row["dossier_id"]).fix
    end
  end
end
