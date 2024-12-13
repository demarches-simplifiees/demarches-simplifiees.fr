# frozen_string_literal: true

class Cron::Datagouv::InstructeurByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 4:00"
  HEADERS = ["mois", "nb_instructeurs_crees_par_mois"]
  FILE_NAME = HEADERS[1]
  DATASET = '6745cdbb3aee5fa1f498d5ef'
  RESOURCE = '72f40d35-4387-4c32-bb83-b99145bf0ea3'

  def perform(*args)
    csv = GenerateOpenDataService.existing_csv(DATASET, RESOURCE, HEADERS)
    resource = csv.empty? ? nil : RESOURCE

    GenerateOpenDataService.months_to_query(csv).map { |period| csv << data_of_range(period) }

    APIDatagouv::API.upload_csv(FILE_NAME, csv, DATASET, resource)
  end

  private

  def data_of_range(range)
    [range.min.strftime("%Y-%m"), Instructeur.where(created_at: range).count]
  end
end
