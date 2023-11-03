class Cron::ExpiredUsersDeletionJob < Cron::CronJob
  self.schedule_expression = "every day at 11 pm"

  def perform(*args)
    return if ENV['EXPIRE_USER_DELETION_JOB_DISABLED'].present?
    ExpiredUsersDeletionService.process_expired
  end
end
