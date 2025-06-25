# frozen_string_literal: true

module Maintenance
  class T20250304BackfillTraitementRevisionIdTask < MaintenanceTasks::Task
    # Documentation: cette tâche assigne la revision_id qui manque aux traitements des vieux dossiers

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      Traitement.joins(dossier: :procedure)
        .where(state: Dossier.states.fetch(:en_construction), revision_id: nil)
        .where('traitements.processed_at = dossiers.depose_at')
    end

    def process(traitement)
      revisions = traitement.dossier
        .procedure
        .revisions
        .where.not(published_at: nil)
        .reorder(:published_at)

      revision = revisions.where(published_at: ..traitement.processed_at).last
      traitement.update!(revision:) if revision.present?
    end
  end
end
