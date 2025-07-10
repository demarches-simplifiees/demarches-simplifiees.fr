# frozen_string_literal: true

module Maintenance
  class T20250709destroyDossierNotificationForAnnotationInstructeurTask < MaintenanceTasks::Task
    # Documentation: cette tâche supprime les DossierNotification de type
    # annotation_instructeur inutiles, en lien avec la PR 11713.

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      DossierNotification
        .where(notification_type: :annotation_instructeur)
        .joins(:dossier)
        .where(dossier: { last_champ_private_updated_at: nil })
    end

    def process(notification)
      notification.destroy!
    end
  end
end
