class ApiEntreprise::Job < ApplicationJob
  DEFAULT_MAX_ATTEMPTS_API_ENTREPRISE_JOBS = 5

  queue_as :api_entreprise

  # BadGateway could mean
  # - acoss: réessayer ultérieurement
  # - bdf: erreur interne
  # so we retry every day for 5 days
  # same logic for ServiceUnavailable
  retry_on ApiEntreprise::API::Error::ServiceUnavailable,
    ApiEntreprise::API::Error::BadGateway,
    wait: 1.day

  # We guess the backend is slow but not broken
  # and the information we are looking for is available
  # so we retry few seconds later (exponentially to avoid overload)
  retry_on ApiEntreprise::API::Error::TimedOut, wait: :exponentially_longer

  # If by the time the job runs the Etablissement has been deleted
  # (it can happen through EtablissementUpdateJob for instance), ignore the job
  discard_on ActiveRecord::RecordNotFound

  rescue_from(ApiEntreprise::API::Error::ResourceNotFound) do |exception|
    error(self, exception)
  end

  rescue_from(ApiEntreprise::API::Error::BadFormatRequest) do |exception|
    error(self, exception)
  end

  def error(job, exception)
    # override ApplicationJob#error to avoid reporting to sentry
  end

  def max_attempts
    ENV.fetch("MAX_ATTEMPTS_API_ENTREPRISE_JOBS", DEFAULT_MAX_ATTEMPTS_API_ENTREPRISE_JOBS).to_i
  end
end
