# frozen_string_literal: true

class Cron::Datagouv::FileByMonthJob < Cron::Datagouv::BaseJob
  self.schedule_expression = "every month at 3:15"
  HEADERS = ["mois", "nb_dossiers_crees_par_mois"]
  FILE_NAME = HEADERS[1]
  RESOURCE = 'fd0fd64e-bbda-428c-87da-50dffdacee78'

  def perform
    csv = data_gouv_csv(RESOURCE, HEADERS)

    missing_months(csv)
      .map { |month| data_for(month:) }
      .each { |data| csv << data }

    APIDatagouv::API.upload_csv(FILE_NAME, csv, DATASET, RESOURCE)
  end

  private

  def data_for(month:)
    [month.strftime(DATE_FORMAT), Dossier.visible_by_user_or_administration.where(created_at: month.all_month).count]
  end
end
