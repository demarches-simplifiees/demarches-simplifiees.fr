class Cron::PurgeManagerAdministrateurSessionsJob < Cron::CronJob
  self.schedule_expression = "every day at 3 am"

  def perform
    AdministrateursProcedure.where(manager: true).destroy_all
  end
end
