class Cron::Datagouv::AccountByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 4:30"
  FILE_NAME = "nb_comptes_crees_par_mois"

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
    User.where(created_at: 1.month.ago.all_month).count
  end
end
