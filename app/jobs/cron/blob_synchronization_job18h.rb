class Cron::BlobSynchronizationJob18h < Cron::CronJob
  self.schedule_expression = "every day at 6 pm"

  def perform(*args)
    S3Synchronization.synchronize(false, Time.zone.now + 175.minutes)
  end
end
