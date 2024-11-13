# frozen_string_literal: true

class Cron::Datagouv::AccountByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 4:30"
  FILE_NAME = "nb_comptes_crees_par_mois"
  HEADERS = ["mois", FILE_NAME]

  def perform(*args)
    file_name = "#{FILE_NAME}_#{date_last_month}.csv"
    GenerateOpenDataCsvService.save_csv_to_tmp(FILE_NAME, HEADERS, data) do |file|
      APIDatagouv::API.upload(file, :statistics_dataset)
    end
  end

  private

  def data
    [[date_last_month, User.where(created_at: 1.month.ago.all_month).count]]
  end

  def date_last_month
    Date.today.prev_month.strftime("%B %Y")
  end
end
