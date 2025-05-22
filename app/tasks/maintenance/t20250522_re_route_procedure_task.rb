# frozen_string_literal: true

module Maintenance
  class T20250522ReRouteProcedureTask < MaintenanceTasks::Task
    # Given a procedure id in argument, run the RoutingEngine again for all dossiers of the procedure (included all states of dossier).
    # This task should be used only if field(s) used for routing have not been changed in procedure revisions. Otherwise, dossiers might be routed the wrong way.
    # Please check history of procedure revisions before using this task.
    # Consider running previously the task below reset_forced_groupe_instructeur, if manual reaffectations should be reset or not.

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    attribute :procedure_id, :string
    validates :procedure_id, presence: true

    def collection
      procedure = Procedure.find(procedure_id.strip)
      procedure.dossiers
    end

    def process(dossier)
      assignment_mode = DossierAssignment.modes.fetch(:tech)

      RoutingEngine.compute(dossier, assignment_mode:)
    end

    def count
      with_statement_timeout("2min") do
        collection.count(:id)
      end
    end
  end
end
