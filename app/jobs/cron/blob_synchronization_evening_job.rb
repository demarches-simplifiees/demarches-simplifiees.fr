class Cron::BlobSynchronizationEveningJob < Cron::CronJob
  self.schedule_expression = "every day at 1 pm"

  def perform(*args)
    S3Synchronization.synchronize(false, Time.zone.now + 170.minutes)
  end
end
