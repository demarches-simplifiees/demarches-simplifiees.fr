# frozen_string_literal: true

class Cron::Datagouv::AccountByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 4:30"
  HEADERS = ["mois", "nb_comptes_crees_par_mois"]
  FILE_NAME = HEADERS[1]
  DATASET = '6745cdbb3aee5fa1f498d5ef'
  RESOURCE = '38195ec9-f10d-44e0-b0aa-fc954ac27c2f'
  DATE_FORMAT = "%Y-%m"

  def perform
    csv = data_gouv_csv

    missing_months(csv)
      .map { |month| data_for(month:) }
      .each { |data| csv << data }

    APIDatagouv::API.upload_csv(FILE_NAME, csv, DATASET, RESOURCE)
  end

  private

  def data_gouv_csv
    APIDatagouv::API.existing_csv(DATASET, RESOURCE) || CSV::Table.new([], headers: HEADERS)
  end

  def missing_months(csv)
    last_date = Date.strptime(csv[-1]['mois'], DATE_FORMAT) if csv.present?

    start_month = last_date.present? ? last_date + 1.month : previous_month

    Enumerator.produce(start_month) { _1 + 1.month }
      .take_while { _1 <= previous_month }
  end

  def previous_month = 1.month.ago.beginning_of_month.to_date

  def data_for(month:)
    [month.strftime(DATE_FORMAT), User.where(created_at: month.all_month).count]
  end
end
