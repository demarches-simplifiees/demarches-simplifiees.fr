class Cron::BlobSynchronizationJob < Cron::CronJob
  self.schedule_expression = "every day at 1 am"

  def perform(*args)
    S3Synchronization.synchronize(false, Time.zone.now + 225.minutes)
  end
end
