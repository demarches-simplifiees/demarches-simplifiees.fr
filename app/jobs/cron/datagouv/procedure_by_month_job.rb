# frozen_string_literal: true

class Cron::Datagouv::ProcedureByMonthJob < Cron::Datagouv::BaseJob
  self.schedule_expression = "every month at 4:15"
  HEADERS = ["mois", "nb_procedures_creees_par_mois"]
  FILE_NAME = HEADERS[1]
  RESOURCE = '5a1a8489-367b-4242-8de1-811572da5147'

  def perform
    super(RESOURCE, HEADERS, FILE_NAME)
  end

  private

  def data_for(month:)
    [month.strftime(DATE_FORMAT), Procedure.where(created_at: month.all_month).count]
  end
end
