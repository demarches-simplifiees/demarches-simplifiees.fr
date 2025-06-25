# frozen_string_literal: true

module Maintenance
  class T20250625BackfillSubmittedRevisionIdTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données pour…

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      Dossier.includes(:traitements)
    end

    def process(dossier)
      submitted_revision_id = dossier.traitements.reverse
        .find { _1.event.in?([:depose, :depose_correction_usager, :depose_correction_instructeur]) }
        &.revision_id

      if submitted_revision_id.present?
        dossier.update_column(:submitted_revision_id, submitted_revision_id)
      end
    end
  end
end
