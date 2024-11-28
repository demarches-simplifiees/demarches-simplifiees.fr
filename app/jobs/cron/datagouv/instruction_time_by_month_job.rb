# frozen_string_literal: true

class Cron::Datagouv::InstructionTimeByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 3:40"
  FILE_NAME = "delais_intruction_par_mois"
  HEADERS = ["mois", "procedure_id", "date_creation", "date_depot", "date_debut_instruction", "date_fin_traitement"]

  def perform(*args)
    GenerateOpenDataCsvService.save_csv_to_tmp(FILE_NAME, HEADERS, data) do |file|
      begin
        APIDatagouv::API.upload(file, :statistics_dataset)
      ensure
        FileUtils.rm(file)
      end
    end
  end

  def data
    # possible adjustment: procedure with at least 300 folders
    Dossier.visible_by_user_or_administration
      .where(created_at: 1.month.ago.all_month)
      .joins('INNER JOIN procedures ON dossiers.revision_id = procedures.published_revision_id')
      .merge(Procedure.publiees.where(estimated_dossiers_count: 300.., opendata: true))
      .order('procedures.id')
      .pluck('procedures.id', 'dossiers.created_at', 'dossiers.depose_at', 'dossiers.en_instruction_at', 'dossiers.processed_at')
      .map do |procedure_id, created_at, depose_at, en_instruction_at, processed_at|
        [
          procedure_id,
          created_at&.to_date&.iso8601,
          depose_at&.to_date&.iso8601,
          en_instruction_at&.to_date&.iso8601,
          processed_at&.to_date&.iso8601
        ]
      end
  end
end
