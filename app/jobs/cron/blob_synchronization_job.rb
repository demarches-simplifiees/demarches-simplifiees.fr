class Cron::BlobSynchronizationJob < Cron::CronJob
  self.schedule_expression = "every day at 1 am"

  def perform(*args)
    S3Synchronization.synchronize(Time.zone.now + 3.hours)
  end
end
