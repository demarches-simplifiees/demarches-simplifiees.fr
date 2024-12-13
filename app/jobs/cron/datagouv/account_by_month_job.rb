# frozen_string_literal: true

class Cron::Datagouv::AccountByMonthJob < Cron::Datagouv::BaseJob
  self.schedule_expression = "every month at 4:30"
  HEADERS = ["mois", "nb_comptes_crees_par_mois"]
  FILE_NAME = HEADERS[1]
  RESOURCE = '2832f158-1920-4f96-af83-ae41c5313558'

  def perform
    csv = data_gouv_csv(RESOURCE, HEADERS)

    missing_months(csv)
      .map { |month| data_for(month:) }
      .each { |data| csv << data }

    APIDatagouv::API.upload_csv(FILE_NAME, csv, DATASET, RESOURCE)
  end

  private

  def data_for(month:)
    [month.strftime(DATE_FORMAT), User.where(created_at: month.all_month).count]
  end
end
