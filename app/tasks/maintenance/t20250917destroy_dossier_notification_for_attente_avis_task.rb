# frozen_string_literal: true

module Maintenance
  class T20250917destroyDossierNotificationForAttenteAvisTask < MaintenanceTasks::Task
    # Documentation: cette tâche supprime les DossierNotification de type
    # attente_avis qui demeurent sur les dossiers traités.

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      DossierNotification
        .joins(:dossier)
        .merge(Dossier.state_termine)
        .where(notification_type: :attente_avis)
    end

    def process(notification)
      notification.destroy!
    end
  end
end
