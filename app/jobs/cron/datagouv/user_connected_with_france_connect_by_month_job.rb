class Cron::Datagouv::UserConnectedWithFranceConnectByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 3:45"
  FILE_NAME = "nb_utilisateurs_connectes_france_connect_par_mois"

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
    User.where(created_at: 1.month.ago.all_month, loged_in_with_france_connect: "particulier").count
  end
end
