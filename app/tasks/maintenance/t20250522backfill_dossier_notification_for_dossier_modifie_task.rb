# frozen_string_literal: true

module Maintenance
  class T20250522backfillDossierNotificationForDossierModifieTask < MaintenanceTasks::Task
    # Documentation: cette tâche permet de créer les DossierNotification manquantes
    # de type 'DOSSIER MODIFIE'

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      Follow
        .where(unfollowed_at: nil)
        .joins(:dossier)
        .where("dossiers.last_champ_updated_at > follows.demande_seen_at")
        .select(:id, :dossier_id, :instructeur_id)
        .includes(:instructeur)
    end

    def process(follow)
      return if follow.instructeur.nil? # we have follow without instructeur !

      DossierNotification.find_or_create_by!(
        dossier_id: follow.dossier_id,
        notification_type: :dossier_modifie,
        instructeur_id: follow.instructeur_id
      ) do |notification|
        notification.display_at = Time.zone.now
      end
    end

    def count
      with_statement_timeout("5min") do
        collection.count(:id)
      end
    end
  end
end
