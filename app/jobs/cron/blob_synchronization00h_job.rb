class Cron::BlobSynchronization00hJob < Cron::CronJob
  self.schedule_expression = "every day at midnight"

  def perform(*args)
    S3Synchronization.perform_step(ENV['OUTSCALE_STEP'], Time.zone.now + 175.minutes)
  end
end
