# frozen_string_literal: true

class Cron::Datagouv::UserConnectedWithFranceConnectByMonthJob < Cron::Datagouv::BaseJob
  self.schedule_expression = "every month at 3:45"
  HEADERS = ["mois", "nb_utilisateurs_connectes_france_connect_par_mois"]
  FILE_NAME = HEADERS[1]
  RESOURCE = 'f688e8aa-5c21-4b61-ba03-b69e33c112f7'

  def perform
    super(RESOURCE, HEADERS, FILE_NAME)
  end

  private

  def data_for(month:)
    [
      month.strftime(DATE_FORMAT),
      User.where(created_at: month.all_month, loged_in_with_france_connect: "particulier").count,
    ]
  end
end
