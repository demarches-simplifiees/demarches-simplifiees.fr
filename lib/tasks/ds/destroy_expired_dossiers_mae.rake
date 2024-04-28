# frozen_string_literal: true

namespace :ds do
  desc 'DS task: destroy_expired_dossiers_mae'
  task destroy_expired_dossiers_mae: :environment do
    dossiers = Dossier.state_termine
      .where("termine_close_to_expiration_notice_sent_at + INTERVAL :expires_in < :now", { now: Time.zone.now, expires_in: '30 days' })
      .joins(:groupe_instructeur)
      .where(groupe_instructeur: { procedure_id: [47787, 47844, 47478, 47865] })
    progress = ProgressReport.new(dossiers.count)

    dossiers.find_each do |dossier|
      dossier.expired_keep_track_and_destroy!
      progress.inc
    end
    progress.finish
  end
end
