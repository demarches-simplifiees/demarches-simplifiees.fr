class ExpiredDossiersDeletionJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    ExpiredDossiersDeletionService.process_expired_dossiers_brouillon
  end
end
