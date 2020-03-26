class DiscardedDossiersDeletionJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    Dossier.discarded_brouillon_expired.destroy_all
    Dossier.discarded_en_construction_expired.destroy_all
  end
end
