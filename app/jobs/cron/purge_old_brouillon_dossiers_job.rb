# frozen_string_literal: true

class Cron::PurgeOldBrouillonDossiersJob < Cron::CronJob
  self.schedule_expression = "every day at 08:30"

  def perform
    Dossier
      .state_brouillon
      .where(updated_at: ..(3.months + 2.weeks).ago)
      .find_each do |dossier|
        dossier.hide_and_keep_track!(:automatic, :not_modified_for_a_long_time)
        DossierMailer.notify_old_brouillon_after_deletion(dossier).deliver_later
      end
  end
end
