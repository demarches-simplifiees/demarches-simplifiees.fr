class ApplicationJob < ActiveJob::Base
  before_perform do |job|
    Rails.logger.info("#{job.class.name} started at #{Time.now}")
  end

  after_perform do |job|
    Rails.logger.info("#{job.class.name} ended at #{Time.now}")
  end
end
