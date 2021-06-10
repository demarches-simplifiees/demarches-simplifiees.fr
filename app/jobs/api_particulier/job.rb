class APIParticulier::Job < ApplicationJob
  DEFAULT_MAX_ATTEMPTS_API_PARTICULIER_JOBS = 5

  queue_as :api_particulier

  # BadGateway could mean
  # - acoss: réessayer ultérieurement
  # - bdf: erreur interne
  # so we retry every day for 5 days
  # same logic for ServiceUnavailable
  rescue_from APIParticulier::Error::ServiceUnavailable, APIParticulier::Error::BadGateway, with: :retry_or_discard

  rescue_from APIParticulier::Error::NotFound, APIParticulier::Error::BadFormatRequest, with: :log_job_exception
  rescue_from EncryptionService::Error, with: :log_job_exception

  # We guess the backend is slow but not broken
  # and the information we are looking for is available
  # so we retry few seconds later (exponentially to avoid overload)
  retry_on APIParticulier::Error::TimedOut, wait: :exponentially_longer

  # If by the time the job runs the Procedure has been deleted
  discard_on ActiveRecord::RecordNotFound

  alias_method :application_job_error, :error
  def error(job, exception)
    # override ApplicationJob#error to avoid reporting to sentry
  end

  def log_job_exception(exception)
    return application_job_error(self, exception) if dossier.nil?

    dossier.log_api_particulier_job_exception(exception)
  end

  def retry_or_discard(exception)
    if executions < max_attempts
      retry_job wait: 1.day
    else
      log_job_exception(exception)
    end
  end

  def max_attempts
    ENV.fetch("MAX_ATTEMPTS_API_PARTICULIER_JOBS", DEFAULT_MAX_ATTEMPTS_API_PARTICULIER_JOBS).to_i
  end

  private

  def dossier
    @dossier ||= Dossier.find(arguments.first) if is_a?(APIParticulier::DossierJob)
  end
end
