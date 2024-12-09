# frozen_string_literal: true

class Cron::Datagouv::InstructeurConnectedByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 4:45"
  HEADERS = ["mois", "nb_instructeurs_connectes_par_mois"]
  FILE_NAME = HEADERS[1]
  DATASET = '6745cdbb3aee5fa1f498d5ef'
  RESOURCE = 'a69785f1-1b96-471c-ad61-5b5c66fa3d21'

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
      Instructeur.joins(:user).where(user: { last_sign_in_at: range }).count
    ]
  end
end
