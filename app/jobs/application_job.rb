class ApplicationJob < ActiveJob::Base
  DEFAULT_MAX_ATTEMPTS_JOBS = 25

  before_perform do |job|
    Rails.logger.info("#{job.class.name} started at #{Time.zone.now}")
  end

  after_perform do |job|
    Rails.logger.info("#{job.class.name} ended at #{Time.zone.now}")
  end

  def error(job, exception)
    Raven.capture_exception(exception)
  end

  def max_attempts
    ENV.fetch("MAX_ATTEMPTS_JOBS", DEFAULT_MAX_ATTEMPTS_JOBS).to_i
  end
end
