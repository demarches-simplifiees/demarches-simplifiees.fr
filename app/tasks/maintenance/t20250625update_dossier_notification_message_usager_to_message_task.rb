# frozen_string_literal: true

module Maintenance
  class T20250625updateDossierNotificationMessageUsagerToMessageTask < MaintenanceTasks::Task
    # Documentation: cette tâche vient update notification_type des
    # instances de DossierNotification de type :message_usager en :message

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      DossierNotification.where(notification_type: [:message, :message_usager])
    end

    def process(notification)
      notification.update!(notification_type: :message)
    end
  end
end
