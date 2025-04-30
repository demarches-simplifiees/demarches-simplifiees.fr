# frozen_string_literal: true

module Maintenance
  class T20250417backfillDossierNotificationForAttenteCorrectionTask < MaintenanceTasks::Task
    # Documentation: cette tâche permet de créer les DossierNotification manquantes
    # de type 'EN ATTENTE DE CORRECTION'

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      Dossier
        .joins('INNER JOIN dossier_corrections ON dossier_corrections.dossier_id = dossiers.id')
        .merge(DossierCorrection.pending)
        .where.not(
          id: DossierNotification
            .where(notification_type: :attente_correction)
            .select(:dossier_id)
        )
        .includes(:followers_instructeurs)
        .map do |dossier|
          [dossier.id, dossier.followers_instructeur_ids]
        end
    end

    def process((dossier_id, instructeur_ids))
      instructeur_ids.each do |instructeur_id|
        DossierNotification.find_or_create_by!(
          dossier_id:,
          notification_type: :attente_correction,
          instructeur_id:
        ) do |notification|
          notification.display_at = Time.current
        end
      end
    end
  end
end
