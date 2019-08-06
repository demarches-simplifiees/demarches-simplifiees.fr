class InstructeurEmailNotificationJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    NotificationService.send_instructeur_email_notification
  end
end
