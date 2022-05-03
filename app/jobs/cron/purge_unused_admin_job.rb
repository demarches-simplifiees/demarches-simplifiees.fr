class Cron::PurgeUnusedAdminJob < Cron::CronJob
  self.schedule_expression = "every monday at 5 am"

  def perform(*args)
    Administrateur.unused.destroy_all
  end
end
