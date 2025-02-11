# frozen_string_literal: true

class Cron::Datagouv::AdministrateurByMonthJob < Cron::Datagouv::BaseJob
  self.schedule_expression = "every month at 3:00"
  HEADERS = ["mois", "nb_administrateurs_crees_par_mois"]
  FILE_NAME = HEADERS[1]
  RESOURCE = '4dd5b8c1-fa7a-4df4-a1c4-758119acec96'

  def perform
    super(RESOURCE, HEADERS, FILE_NAME)
  end

  private

  def data_for(month:)
    [month.strftime(DATE_FORMAT), Administrateur.where(created_at: month.all_month).count]
  end
end
