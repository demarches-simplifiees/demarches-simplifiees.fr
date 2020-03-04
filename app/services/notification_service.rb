class NotificationService
  class << self
    def send_instructeur_email_notification
      Instructeur
        .includes(assign_to: { procedure: :dossiers })
        .where(assign_tos: { daily_email_notifications_enabled: true })
        .find_in_batches { |instructeurs| send_batch_of_instructeurs_email_notification(instructeurs) }
    end

    private

    def send_batch_of_instructeurs_email_notification(instructeurs)
      instructeurs
        .map { |instructeur| [instructeur, instructeur.email_notification_data] }
        .reject { |(_instructeur, data)| data.empty? }
        .each { |(instructeur, data)| InstructeurMailer.send_notifications(instructeur, data).deliver_later }
    end
  end
end
