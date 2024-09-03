# frozen_string_literal: true

class Cron::PurgeManagerAdministrateurSessionsJob < Cron::CronJob
  self.schedule_expression = "every day at 02:45"

  def perform
    # TODO: add id column to administrateurs_procedures and use destroy_all
    AdministrateursProcedure.where(manager: true).delete_all
    AssignTo.where(manager: true).destroy_all
  end
end
