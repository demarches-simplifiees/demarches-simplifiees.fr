class Cron::InstructeurEmailNotificationJob < Cron::CronJob
  self.schedule_expression = "from monday through friday at 8 am"

  def perform(*args)
    NotificationService.send_instructeur_email_notification
  end
end
