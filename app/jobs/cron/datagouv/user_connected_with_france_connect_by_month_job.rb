# frozen_string_literal: true

class Cron::Datagouv::UserConnectedWithFranceConnectByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 3:45"
  HEADERS = ["mois", "nb_utilisateurs_connectes_france_connect_par_mois"]
  FILE_NAME = HEADERS[1]
  DATASET = '6745cdbb3aee5fa1f498d5ef'
  RESOURCE = '2e73fb50-557c-41c9-8b9e-7716f3c63be4'

  def perform(*args)
    csv = GenerateOpenDataService.existing_csv(DATASET, RESOURCE, HEADERS)
    resource = csv.empty? ? nil : RESOURCE

    GenerateOpenDataService.months_to_query(csv).map { |period| csv << data_of_range(period) }

    APIDatagouv::API.upload_csv(FILE_NAME, csv, DATASET, resource)
  end

  private

  def data_of_range(range)
    [
      range.min.strftime("%Y-%m"),
      User.where(created_at: range, loged_in_with_france_connect: "particulier").count
    ]
  end
end
