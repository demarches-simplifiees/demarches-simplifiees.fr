# frozen_string_literal: true

class Cron::Datagouv::FileDeposeByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 5:00"
  HEADERS = ["mois", "nb_dossiers_deposes_par_mois"]
  FILE_NAME = HEADERS[1]
  DATASET = '6745cdbb3aee5fa1f498d5ef'
  RESOURCE = 'f2bf1632-fb1b-4e28-9e59-2b89e1646ace'

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
      Dossier.visible_by_user_or_administration
        .where(depose_at: range).count +
      DeletedDossier
        .where(depose_at: range).count
    ]
  end
end
