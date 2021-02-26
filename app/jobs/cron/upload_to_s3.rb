class Cron::UploadToS3Job < Cron::CronJob
  self.schedule_expression = "every day at 1 pm"

  def perform(*args)
    S3Synchronization.synchronize(Time.zone.now + 3.hours)
  end
end
