# frozen_string_literal: true

module Maintenance
  class T20251209destroyDossierNotificationForDossierSuppressionTask < MaintenanceTasks::Task
    # Documentation: cette tâche permet de supprimer les notifications de type
    # dossier_suppression erronée introduite via T20251110backfillDossierNotificationForDossierSuppressionTask
    # qui concerne les dossiers supprimés uniquement par l'administration :
    # - si le dossier n'est pas expiré :
    #   - la notif est en trop lorsque le dossier n'est pas supprimé par l'usager ;
    #   - le délai affiché par la notif peut être erronée si le dossier est supprimé aussi par l'usager ;
    # - si le dossier est expiré, il se peut que le délai affiché par la notif soit erroné.
    # Il convient ensuite de refaire tourner la MT ci-dessus qui a été corrigée dans la PR#12427.

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      DossierNotification
        .where(notification_type: :dossier_suppression)
        .joins(:dossier)
        .merge(Dossier.hidden_by_administration)
    end

    def process(notification)
      notification.delete
    end
  end
end
