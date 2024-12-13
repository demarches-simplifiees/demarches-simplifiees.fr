# frozen_string_literal: true

class Cron::Datagouv::AdministrateurByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 3:00"
  HEADERS = ["mois", "nb_administrateurs_crees_par_mois"]
  FILE_NAME = HEADERS[1]
  DATASET = '6745cdbb3aee5fa1f498d5ef'
  RESOURCE = '2a26eece-b9e7-43ea-ae50-7101c7187aba'

  def perform(*args)
    csv = GenerateOpenDataService.existing_csv(DATASET, RESOURCE, HEADERS)
    resource = csv.empty? ? nil : RESOURCE

    GenerateOpenDataService.months_to_query(csv).map { |period| csv << data_of_range(period) }

    APIDatagouv::API.upload_csv(FILE_NAME, csv, DATASET, resource)
  end

  private

  def data_of_range(range)
    [range.min.strftime("%Y-%m"), Administrateur.where(created_at: range).count]
  end
end
