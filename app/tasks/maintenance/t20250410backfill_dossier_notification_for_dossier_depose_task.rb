# frozen_string_literal: true

module Maintenance
  class T20250410backfillDossierNotificationForDossierDeposeTask < MaintenanceTasks::Task
    # Documentation: cette tâche permet de créer les DossierNotification manquantes
    # de type 'dossier déposé depuis X jours'

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      Dossier
        .by_statut('a-suivre')
        .where('depose_at <= ?', Time.current - 7.days)
        .left_joins(:dossier_notifications)
        .where('dossier_notifications.id IS NULL OR dossier_notifications.notification_type != ?', 'dossier_depose')
    end

    def process(dossier)
      params = {
        dossier_id: dossier.id,
        notification_type: 'dossier_depose',
        instructeur_id: nil,
        groupe_instructeur_id: dossier.groupe_instructeur_id,
        display_at: dossier.depose_at + 7.days
      }

      DossierNotification.create!(params)
    end
  end
end
