class AutoArchiveProcedureJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    Procedure.publiees.where("auto_archive_on <= ?", Date.today).each do |procedure|
      procedure
        .dossiers
        .state_en_construction
        .find_each(&:passer_automatiquement_en_instruction!)

      procedure.archive!
    end
  end
end
