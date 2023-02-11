class Cron::PurgeOldEmailEventJob < Cron::CronJob
  self.schedule_expression = "every week at 3:00"

  def perform
    EmailEvent.outdated.destroy_all
  end
end
