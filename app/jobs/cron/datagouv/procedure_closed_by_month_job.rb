# frozen_string_literal: true

class Cron::Datagouv::ProcedureClosedByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 4:00"
  HEADERS = ["mois", "nb_procedures_closes_par_mois"]
  FILE_NAME = HEADERS[1]
  DATASET = '6745cdbb3aee5fa1f498d5ef'
  RESOURCE = '7039aeaa-156d-4d85-bb0d-ac27470a1180'

  def perform(*args)
    csv = GenerateOpenDataService.existing_csv(DATASET, RESOURCE, HEADERS)
    resource = csv.empty? ? nil : RESOURCE

    GenerateOpenDataService.months_to_query(csv).map { |period| csv << data_of_range(period) }

    APIDatagouv::API.upload_csv(FILE_NAME, csv, DATASET, resource)
  end

  private

  def data_of_range(range)
    [range.min.strftime("%Y-%m"), Procedure.where(closed_at: range).count]
  end
end
