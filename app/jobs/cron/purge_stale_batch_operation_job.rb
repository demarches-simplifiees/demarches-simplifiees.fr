class Cron::PurgeStaleBatchOperationJob < Cron::CronJob
  self.schedule_expression = "every 5 minutes"

  def perform
    BatchOperation.stale.destroy_all
    BatchOperation.stuck.destroy_all
  end
end
