# frozen_string_literal: true

class Cron::Datagouv::InstructeurConnectedByMonthJob < Cron::Datagouv::BaseJob
  self.schedule_expression = "every month at 4:45"
  HEADERS = ["mois", "nb_instructeurs_connectes_par_mois"]
  FILE_NAME = HEADERS[1]
  RESOURCE = 'f15e8857-06dc-4671-8139-887205c7337a'

  def perform
    super(RESOURCE, HEADERS, FILE_NAME)
  end

  private

  def data_for(month:)
    [
      month.strftime(DATE_FORMAT),
      Instructeur.joins(:user).where(user: { last_sign_in_at: month.all_month }).count,
    ]
  end
end
