# frozen_string_literal: true

module Maintenance
  class T20251110backfillDossierNotificationForDossierSuppressionTask < MaintenanceTasks::Task
    # Documentation: cette tâche permet de rattraper les notifications de type
    # :dossier_suppression

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      Dossier
        .hidden_by_administration
        .or(Dossier.hidden_by_expired)
        .includes(groupe_instructeur: :instructeurs)
    end

    def process(dossier)
      dossier.groupe_instructeur.instructeur_ids.each do |instructeur_id|
        DossierNotification.find_or_create_by!(
          dossier_id: dossier.id,
          notification_type: :dossier_suppression,
          instructeur_id: instructeur_id
        ) do |notification|
          notification.display_at = [dossier.hidden_by_administration_at, dossier.hidden_by_expired_at].compact.min
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
