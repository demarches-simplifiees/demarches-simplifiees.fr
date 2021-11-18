class Cron::BlobSynchronizationEveningJob < Cron::CronJob
  self.schedule_expression = "every day at 6 pm"

  def perform(*args)
    S3Synchronization.synchronize(false, Time.zone.now + 180.minutes)
  end
end
