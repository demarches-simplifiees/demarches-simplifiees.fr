# frozen_string_literal: true

module Maintenance
  class T20250424backfillDossierNotificationForAttenteAvisTask < MaintenanceTasks::Task
    # Documentation: cette tâche permet de créer les DossierNotification manquantes
    # de type 'EN ATTENTE D'AVIS'

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      Dossier
        .joins(:avis)
        .merge(Avis.without_answer)
        .includes(:followers_instructeurs)
    end

    def process(dossier)
      dossier.followers_instructeur_ids.each do |instructeur_id|
        DossierNotification.find_or_create_by!(
          dossier:,
          notification_type: :attente_avis,
          instructeur_id:
        ) do |notification|
          notification.display_at = Time.current
        end
      end
    end
  end
end
