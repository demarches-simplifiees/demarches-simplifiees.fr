class AutoArchiveProcedureJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    Procedure.publiees.where("auto_archive_on <= ?", Date.today).each do |procedure|
      gestionnaire = procedure.gestionnaire_for_cron_job

      procedure.dossiers.state_en_construction.find_each do |dossier|
        dossier.passer_en_instruction!(gestionnaire)
      end

      procedure.archive!
    end
  end
end
