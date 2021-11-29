class Cron::BlobSynchronizationJob00h < Cron::CronJob
  self.schedule_expression = "every day at midnight"

  def perform(*args)
    S3Synchronization.synchronize(false, Time.zone.now + 175.minutes)
  end
end
