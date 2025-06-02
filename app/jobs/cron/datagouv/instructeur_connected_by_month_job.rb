# frozen_string_literal: true

class Cron::Datagouv::InstructeurConnectedByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 4:45"
  FILE_NAME = "nb_instructeurs_connectes_par_mois"

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
    Instructeur.joins(:user).where(user: { last_sign_in_at: 1.month.ago.all_month }).count
  end
end
