# frozen_string_literal: true

class Cron::NotifyOldBrouillonDossiersSoonDeletedJob < Cron::CronJob
  self.schedule_expression = "every day at 6:00"

  def perform
    Dossier
      .state_brouillon
      .where(updated_at: ..3.months.ago)
      .where("notified_soon_deleted_sent_at IS NULL OR notified_soon_deleted_sent_at < updated_at")
      .find_each do |dossier|
        DossierMailer.notify_old_brouillon_soon_deleted(dossier).deliver_later(wait: rand(0..3.hours))
        dossier.update_column(:notified_soon_deleted_sent_at, Time.zone.now)
      end
  end
end
