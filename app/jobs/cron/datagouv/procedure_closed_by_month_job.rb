# frozen_string_literal: true

class Cron::Datagouv::ProcedureClosedByMonthJob < Cron::Datagouv::BaseJob
  self.schedule_expression = "every month at 4:00"
  HEADERS = ["mois", "nb_procedures_closes_par_mois"]
  FILE_NAME = HEADERS[1]
  RESOURCE = '6ea8ceff-a4ea-4b2c-98d8-5d4646c90113'

  def perform
    csv = data_gouv_csv(RESOURCE, HEADERS)

    missing_months(csv)
      .map { |month| data_for(month:) }
      .each { |data| csv << data }

    APIDatagouv::API.upload_csv(FILE_NAME, csv, DATASET, RESOURCE)
  end

  private

  def data_for(month:)
    [month.strftime(DATE_FORMAT), Procedure.where(closed_at: month.all_month).count]
  end
end
