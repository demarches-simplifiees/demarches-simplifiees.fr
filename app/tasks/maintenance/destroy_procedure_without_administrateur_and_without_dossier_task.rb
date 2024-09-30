# frozen_string_literal: true

module Maintenance
  class DestroyProcedureWithoutAdministrateurAndWithoutDossierTask < MaintenanceTasks::Task
    # suppression de procédures closes sans admin et sans dossier
    # 2024-03-18-01 PR #10125
    def collection
      Procedure.with_discarded.where.missing(:administrateurs, :dossiers)
    end

    def process(procedure)
      procedure.destroy!
    end
  end
end
