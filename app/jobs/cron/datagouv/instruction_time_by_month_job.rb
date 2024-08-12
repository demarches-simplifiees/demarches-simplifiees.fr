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
    # possible adjustment: procedure with at least 20 folders
    data = Dossier.joins(:procedure)
      .where(revision_id: Procedure.select(:published_revision_id).where(estimated_dossiers_count: 20.., opendata: true))
      .where(created_at: 1.month.ago.all_month)
      .order(:procedure_id)
      .pluck(:procedure_id, :created_at, :depose_at, :en_instruction_at, :processed_at)

    data.map! do |procedure_id, created_at, depose_at, en_instruction_at, processed_at|
      [
        procedure_id,
        created_at.to_date.iso8601,
        depose_at&.to_date&.iso8601,
        en_instruction_at&.to_date&.iso8601,
        processed_at&.to_date&.iso8601
      ]
    end
  end
end
