# frozen_string_literal: true

class Cron::ExpiredUsersDeletionJob < Cron::CronJob
  self.schedule_expression = Expired.schedule_at(self)
  discard_on StandardError

  def perform(*args)
    return if ENV['EXPIRE_USER_DELETION_JOB_LIMIT'].blank?
    Expired::UsersDeletionService.new.process_expired
  end
end
