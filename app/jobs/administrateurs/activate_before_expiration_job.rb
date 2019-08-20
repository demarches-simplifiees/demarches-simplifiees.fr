class Administrateurs::ActivateBeforeExpirationJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    Administrateur
      .includes(:user)
      .inactive
      .where(created_at: 3.days.ago.all_day)
      .each { |a| a.user.remind_invitation! }
  end
end
