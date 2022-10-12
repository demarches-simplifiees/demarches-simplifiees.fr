class ApplicationJob < ActiveJob::Base
  include ActiveJob::RetryOnTransientErrors

  DEFAULT_MAX_ATTEMPTS_JOBS = 25

  attr_writer :request_id

  around_perform do |job, block|
    Rails.logger.info("#{job.class.name} started at #{Time.zone.now}")
    Current.set(request_id: job.request_id) do
      block.call
    end
    Rails.logger.info("#{job.class.name} ended at #{Time.zone.now}")
  end

  def error(job, exception)
    Sentry.capture_exception(exception)
  end

  def max_attempts
    ENV.fetch("MAX_ATTEMPTS_JOBS", DEFAULT_MAX_ATTEMPTS_JOBS).to_i
  end

  def request_id
    @request_id ||= Current.request_id
  end

  def serialize
    super.merge('request_id' => request_id)
  end

  def deserialize(job_data)
    super
    self.request_id = job_data['request_id']
  end
end
