# frozen_string_literal: true

module Maintenance
  class T20250522resetForcedGroupInstructeurTask < MaintenanceTasks::Task
    # This task reset the forced_groupe_instructeur field for all dossiers of a procedure.
    # It might be used before running T20250522ReRouteProcedureTask

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    attribute :procedure_id, :string
    validates :procedure_id, presence: true

    def collection
      procedure = Procedure.find(procedure_id.strip)
      procedure.dossiers
    end

    def process(dossier)
      dossier.update(forced_groupe_instructeur: false)
    end

    def count
      with_statement_timeout("2min") do
        collection.count(:id)
      end
    end
  end
end
