class ApiEntreprise::Job < ApplicationJob
  queue_as :api_entreprise

  retry_on ApiEntreprise::API::ServiceUnavailable,
    ApiEntreprise::API::BadGateway,
    wait: 1.day

  DEFAULT_MAX_ATTEMPTS_API_ENTREPRISE_JOBS = 5

  # If by the time the job runs the Etablissement has been deleted
  # (it can happen through EtablissementUpdateJob for instance), ignore the job
  discard_on ActiveRecord::RecordNotFound

  rescue_from(ApiEntreprise::API::ResourceNotFound) do |exception|
    error(self, exception)
  end

  rescue_from(ApiEntreprise::API::BadFormatRequest) do |exception|
    error(self, exception)
  end

  def error(job, exception)
    # override ApplicationJob#error to avoid reporting to sentry
  end

  def max_attempts
    ENV.fetch("MAX_ATTEMPTS_API_ENTREPRISE_JOBS", DEFAULT_MAX_ATTEMPTS_API_ENTREPRISE_JOBS).to_i
  end
end
