class Administrateurs::ActivateBeforeExpirationJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    Administrateur.inactive.where(created_at: 2.days.ago.all_day).each do |a|
      AdministrateurMailer.activate_before_expiration(a).deliver_later
    end
  end
end
