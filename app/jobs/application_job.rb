class ApplicationJob < ActiveJob::Base
  before_perform do |job|
    Rails.logger.info("#{job.class.name} started at #{Time.zone.now}")
  end

  after_perform do |job|
    Rails.logger.info("#{job.class.name} ended at #{Time.zone.now}")
  end

  rescue_from(ApiEntreprise::API::ResourceNotFound) do |exception|
    error(self, exception)
  end

  rescue_from(ApiEntreprise::API::BadFormatRequest) do |exception|
    error(self, exception)
  end

  def error(job, exception)
    Raven.capture_exception(exception)
  end
end
