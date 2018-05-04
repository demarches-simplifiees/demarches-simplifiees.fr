class Administrateurs::ActivateBeforeExpirationJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    Administrateur.inactive.where(created_at: 3.days.ago.all_day).each do |a|
      a.remind_invitation!
    end
  end
end
