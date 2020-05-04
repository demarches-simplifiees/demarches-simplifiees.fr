class DiscardedDossiersDeletionJob < CronJob
  self.schedule_expression = "every day at 2 am"

  def perform(*args)
    Dossier.discarded_brouillon_expired.destroy_all
    Dossier.discarded_en_construction_expired.destroy_all
  end
end
