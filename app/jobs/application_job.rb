# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  include ActiveJob::RetryOnTransientErrors

  DEFAULT_MAX_ATTEMPTS_JOBS = 25

  attr_writer :request_id

  before_perform do |job|
    # Set url_options for ActiveStorage in job context (needed for Disk service only)
    if ActiveStorage::Blob.service.name == :local
      ActiveStorage::Current.url_options = Rails.application.routes.default_url_options
    end

    arg = job.arguments.first

    case arg
    when Dossier
      Sentry.set_tags(dossier: arg.id, procedure: arg.procedure.id)
    when Procedure
      Sentry.set_tags(procedure: arg.id)
    end
  end

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

  def max_run_time
    4.hours # decrease run time by default
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
