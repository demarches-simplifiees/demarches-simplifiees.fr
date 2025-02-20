# frozen_string_literal: true

class Cron::Datagouv::AccountByMonthJob < Cron::Datagouv::BaseJob
  self.schedule_expression = "every month at 4:30"
  HEADERS = ["mois", "nb_comptes_crees_par_mois"]
  FILE_NAME = HEADERS[1]
  RESOURCE = '38195ec9-f10d-44e0-b0aa-fc954ac27c2f'

  def perform
    super(RESOURCE, HEADERS, FILE_NAME)
  end

  private

  def data_for(month:)
    [month.strftime(DATE_FORMAT), User.where(created_at: month.all_month).count]
  end
end
