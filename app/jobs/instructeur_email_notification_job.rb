class InstructeurEmailNotificationJob < CronJob
  self.schedule_expression = "from monday through friday at 10 am"

  def perform(*args)
    NotificationService.send_instructeur_email_notification
  end
end
