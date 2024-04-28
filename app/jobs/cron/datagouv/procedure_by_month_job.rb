# frozen_string_literal: true

class Cron::Datagouv::ProcedureByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 4:15"
  FILE_NAME = "nb_procedures_creees_par_mois"

  def perform(*args)
    GenerateOpenDataCsvService.save_csv_to_tmp(FILE_NAME, data) do |file|
      begin
        APIDatagouv::API.upload(file, :statistics_dataset)
      ensure
        FileUtils.rm(file)
      end
    end
  end

  def data
    Procedure.where(created_at: 1.month.ago.all_month).count
  end
end
