class SeekAndDestroyExpiredDossiersJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    Dossier.send_brouillon_expiration_notices
    Dossier.destroy_brouillons_and_notify
    Dossier.notify_draft_not_submitted
  end
end
