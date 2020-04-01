class AutoArchiveProcedureJob < CronJob
  self.schedule_expression = "every 1 minute"

  def perform(*args)
    Procedure.publiees.where("auto_archive_on <= ?", Time.zone.today).each do |procedure|
      procedure
        .dossiers
        .state_en_construction
        .find_each(&:passer_automatiquement_en_instruction!)

      procedure.close!
    end
  end
end
