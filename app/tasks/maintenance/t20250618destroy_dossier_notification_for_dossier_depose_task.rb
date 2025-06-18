# frozen_string_literal: true

module Maintenance
  class T20250618destroyDossierNotificationForDossierDeposeTask < MaintenanceTasks::Task
    # Documentation: cette tâche permet de supprimer les badges de notification de
    # type "dossier_depose" qui ont pu être inutilement générés, notamment avant
    # le fix de la PR 11782

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      DossierNotification
        .joins(:dossier)
        .merge(Dossier.state_not_en_construction)
        .where(notification_type: :dossier_depose)
    end

    def process(notification)
      notification.destroy!
    end
  end
end
