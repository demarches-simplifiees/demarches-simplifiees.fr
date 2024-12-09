# frozen_string_literal: true

class Cron::Datagouv::InstructeurByMonthJob < Cron::Datagouv::BaseJob
  self.schedule_expression = "every month at 4:00"
  HEADERS = ["mois", "nb_instructeurs_crees_par_mois"]
  FILE_NAME = HEADERS[1]
  RESOURCE = '183b77d0-8cf0-4a21-a2e6-5824f178395e'

  def perform
    super(RESOURCE, HEADERS, FILE_NAME)
  end

  private

  def data_for(month:)
    [month.strftime(DATE_FORMAT), Instructeur.where(created_at: month.all_month).count]
  end
end
