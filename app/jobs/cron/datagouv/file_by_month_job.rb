# frozen_string_literal: true

class Cron::Datagouv::FileByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 3:15"
  HEADERS = ["mois", "nb_dossiers_crees_par_mois"]
  FILE_NAME = HEADERS[1]
  DATASET = '6745cdbb3aee5fa1f498d5ef'
  RESOURCE = '5712aaa8-9f96-4761-aa61-1931d848c874'

  def perform(*args)
    csv = GenerateOpenDataService.existing_csv(DATASET, RESOURCE, HEADERS)
    resource = csv.empty? ? nil : RESOURCE

    GenerateOpenDataService.months_to_query(csv).map { |period| csv << data_of_range(period) }

    APIDatagouv::API.upload_csv(FILE_NAME, csv, DATASET, resource)
  end

  private

  def data_of_range(range)
    [range.min.strftime("%Y-%m"), Dossier.visible_by_user_or_administration.where(created_at: range).count]
  end
end
