class InstructeurEmailNotificationJob < CronJob
  self.cron_expression = "0 10 * * MON-FRI"

  def perform(*args)
    NotificationService.send_instructeur_email_notification
  end
end
