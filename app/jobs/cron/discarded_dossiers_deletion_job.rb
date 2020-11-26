class Cron::DiscardedDossiersDeletionJob < Cron::CronJob
  self.schedule_expression = "every day at 2 am"

  def perform(*args)
    DossierOperationLog.where(dossier: Dossier.discarded_en_construction_expired)
      .where.not(operation: DossierOperationLog.operations.fetch(:supprimer))
      .destroy_all
    DossierOperationLog.where(dossier: Dossier.discarded_termine_expired)
      .where.not(operation: DossierOperationLog.operations.fetch(:supprimer))
      .destroy_all

    Dossier.discarded_brouillon_expired.destroy_all
    Dossier.discarded_en_construction_expired.destroy_all
    Dossier.discarded_termine_expired.destroy_all
  end
end
