class Cron::ProcedureProcessSVASVRJob < Cron::CronJob
  self.schedule_expression = "every day at 01:15"

  def perform
    Procedure.sva_svr.find_each do |procedure|
      procedure.dossiers.state_en_construction_ou_instruction.find_each do |dossier|
        ProcedureSVASVRProcessDossierJob.perform_later(dossier)
      end
    end
  end
end
