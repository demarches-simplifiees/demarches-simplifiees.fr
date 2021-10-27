class Cron::PurgeStaleTransfersJob < Cron::CronJob
  self.schedule_expression = "every day at midnight"

  def perform
    DossierTransfer.destroy_stale
  end
end
