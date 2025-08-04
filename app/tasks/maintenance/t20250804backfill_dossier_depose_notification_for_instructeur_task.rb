# frozen_string_literal: true

module Maintenance
  class T20250804backfillDossierDeposeNotificationForInstructeurTask < MaintenanceTasks::Task
    # Documentation: cette tâche permet de créer les DossierNotification manquantes
    # de type 'dossier déposé depuis X jours' dorénavant rattachées à un instructeur

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      Dossier
        .state_en_construction
        .by_statut('a-suivre')
        .select(:id, :groupe_instructeur_id, :depose_at)
        .includes(groupe_instructeur: :instructeurs)
    end

    def process(dossier)
      dossier.groupe_instructeur.instructeur_ids.each do |instructeur_id|
        DossierNotification.find_or_create_by!(
          dossier_id: dossier.id,
          notification_type: :dossier_depose,
          instructeur_id: instructeur_id
        ) do |notification|
          notification.display_at = dossier.depose_at + DossierNotification::DELAY_DOSSIER_DEPOSE
        end
      end
    end

    def count
      with_statement_timeout("5min") do
        collection.count(:id)
      end
    end
  end
end
