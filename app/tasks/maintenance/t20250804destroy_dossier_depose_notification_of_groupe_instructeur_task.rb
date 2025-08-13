# frozen_string_literal: true

module Maintenance
  class T20250804destroyDossierDeposeNotificationOfGroupeInstructeurTask < MaintenanceTasks::Task
    # Documentation: cette tâche permet de supprimer toutes les notification de
    # type dossier_depose qui sont rattachées à un groupe instructeur

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      DossierNotification
        .where(notification_type: :dossier_depose)
        .where(instructeur_id: nil)
        .in_batches
    end

    def process(batch_of_notifications)
      batch_of_notifications.delete_all
    end

    def count
      with_statement_timeout("5min") do
        DossierNotification
          .where(notification_type: :dossier_depose)
          .where(instructeur_id: nil)
          .count(:id) / 1000
      end
    end
  end
end
