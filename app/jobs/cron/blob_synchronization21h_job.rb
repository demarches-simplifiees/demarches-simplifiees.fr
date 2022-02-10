class Cron::BlobSynchronization21hJob < Cron::CronJob
  self.schedule_expression = "every day at 9 pm"

  def perform(*args)
    S3Synchronization.perform_step(ENV['OUTSCALE_STEP'], Time.zone.now + 175.minutes)
  end
end
