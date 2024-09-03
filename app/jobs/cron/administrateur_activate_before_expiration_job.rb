# frozen_string_literal: true

class Cron::AdministrateurActivateBeforeExpirationJob < Cron::CronJob
  self.schedule_expression = "every day at 08:00"

  def perform(*args)
    Administrateur
      .includes(:user)
      .inactive
      .where(created_at: 3.days.ago.all_day)
      .find_each { |a| a.user.remind_invitation! }
  end
end
