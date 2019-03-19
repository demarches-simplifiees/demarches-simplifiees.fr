class GestionnaireEmailNotificationJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    NotificationService.send_gestionnaire_email_notification
  end
end
