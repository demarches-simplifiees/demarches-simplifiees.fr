class NotificationService
  class << self
    def send_gestionnaire_email_notification
      Gestionnaire
        .includes(assign_to: { procedure: :dossiers })
        .where(assign_tos: { email_notifications_enabled: true })
        .find_in_batches { |gestionnaires| send_batch_of_gestionnaires_email_notification(gestionnaires) }
    end

    private

    def send_batch_of_gestionnaires_email_notification(gestionnaires)
      gestionnaires
        .map { |gestionnaire| [gestionnaire, gestionnaire.email_notification_data] }
        .reject { |(_gestionnaire, data)| data.empty? }
        .each { |(gestionnaire, data)| GestionnaireMailer.send_notifications(gestionnaire, data).deliver_later }
    end
  end
end
