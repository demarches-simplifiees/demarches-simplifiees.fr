class ApplicationJob < ActiveJob::Base
  before_perform do |job|
    Rails.logger.info("#{job.class.name} started at #{Time.zone.now}")
  end

  after_perform do |job|
    Rails.logger.info("#{job.class.name} ended at #{Time.zone.now}")
  end

  def error(job, exception)
    Raven.capture_exception(exception)
  end
end
