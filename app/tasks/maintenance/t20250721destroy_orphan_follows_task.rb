# frozen_string_literal: true

module Maintenance
  class T20250721destroyOrphanFollowsTask < MaintenanceTasks::Task
    # Documentation: cette tâche vient supprimer les follows orphelins dûs
    # à la suppression d'un dossier ou d'un instructeur

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      Follow
        .left_joins(:instructeur, :dossier)
        .where('instructeurs.id IS NULL OR dossiers.id IS NULL')
    end

    def process(follow)
      follow.destroy!
    end

    def count
      with_statement_timeout("5min") do
        collection.count(:id)
      end
    end
  end
end
