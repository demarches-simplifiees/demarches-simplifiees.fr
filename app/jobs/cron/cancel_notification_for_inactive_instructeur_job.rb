# frozen_string_literal: true

class Cron::CancelNotificationForInactiveInstructeurJob < Cron::CronJob
  self.schedule_expression = "from monday through friday at 3 am"

  def perform(*args)
    AssignTo.cancel_notifications_for_inactive_instructeurs
  end
end
