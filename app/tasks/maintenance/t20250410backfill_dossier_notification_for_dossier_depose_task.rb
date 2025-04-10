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
        .where(depose_at: ..7.days.ago)
        .select(:id, :groupe_instructeur_id, :depose_at)
    end

    def process(dossier)
      DossierNotification.find_or_create_by!(
        dossier_id: dossier.id,
        notification_type: :dossier_depose,
        groupe_instructeur_id: dossier.groupe_instructeur_id
      ) do |notification|
        notification.display_at = dossier.depose_at + 7.days
      end
    end
  end
end
