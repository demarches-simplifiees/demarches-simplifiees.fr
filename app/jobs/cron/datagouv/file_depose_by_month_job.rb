# frozen_string_literal: true

class Cron::Datagouv::FileDeposeByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 5:00"
  FILE_NAME = "nb_dossiers_deposes_par_mois"

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
    Dossier.visible_by_user_or_administration
      .where(depose_at: 1.month.ago.all_month).count + DeletedDossier
        .where(depose_at: 1.month.ago.all_month).count
  end
end
