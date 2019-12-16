class SeekAndDestroyExpiredDossiersJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    SeekAndDestroyExpiredDossiersService.action_dossier_brouillon
    SeekAndDestroyExpiredDossiersService.action_dossier_en_constuction
  end
end
