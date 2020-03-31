class DiscardedDossiersDeletionJob < CronJob
  self.cron_expression = "0 7 * * *"

  def perform(*args)
    Dossier.discarded_brouillon_expired.destroy_all
    Dossier.discarded_en_construction_expired.destroy_all
  end
end
