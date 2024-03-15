# frozen_string_literal: true

module Maintenance
  class DestroyProcedureWithoutAdministrateurAndWithoutDossierTask < MaintenanceTasks::Task
    def collection
      Procedure.with_discarded.where.missing(:administrateurs, :dossiers)
    end

    def process(procedure)
      procedure.destroy!
    end
  end
end
