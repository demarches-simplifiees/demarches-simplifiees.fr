class Cron::PurgeManagerAdministrateurSessionsJob < Cron::CronJob
  self.schedule_expression = "every day at 3 am"

  def perform
    # TODO: add id column to administrateurs_procedures and use destroy_all
    AdministrateursProcedure.where(manager: true).delete_all
  end
end
