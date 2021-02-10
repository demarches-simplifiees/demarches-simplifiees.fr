class APIEntreprise::Job < ApplicationJob
  DEFAULT_MAX_ATTEMPTS_API_ENTREPRISE_JOBS = 5

  queue_as :api_entreprise

  # BadGateway could mean
  # - acoss: réessayer ultérieurement
  # - bdf: erreur interne
  # so we retry every day for 5 days
  # same logic for ServiceUnavailable
  rescue_from(APIEntreprise::API::Error::ServiceUnavailable) do |exception|
    retry_or_discard(exception)
  end
  rescue_from(APIEntreprise::API::Error::BadGateway) do |exception|
    retry_or_discard(exception)
  end

  # We guess the backend is slow but not broken
  # and the information we are looking for is available
  # so we retry few seconds later (exponentially to avoid overload)
  retry_on APIEntreprise::API::Error::TimedOut, wait: :exponentially_longer

  # If by the time the job runs the Etablissement has been deleted
  # (it can happen through EtablissementUpdateJob for instance), ignore the job
  discard_on ActiveRecord::RecordNotFound

  rescue_from(APIEntreprise::API::Error::ResourceNotFound) do |exception|
    error(self, exception)
  end

  rescue_from(APIEntreprise::API::Error::BadFormatRequest) do |exception|
    error(self, exception)
  end

  def error(job, exception)
    # override ApplicationJob#error to avoid reporting to sentry
  end

  def log_job_exception(exception)
    if etablissement.present?
      if etablissement.dossier.present?
        etablissement.dossier.log_api_entreprise_job_exception(exception)
      elsif etablissement.champ.present?
        etablissement.champ.log_fetch_external_data_exception(exception)
      end
    end
  end

  def retry_or_discard(exception)
    if executions < max_attempts
      retry_job wait: 1.day
    else
      log_job_exception(exception)
    end
  end

  def max_attempts
    ENV.fetch("MAX_ATTEMPTS_API_ENTREPRISE_JOBS", DEFAULT_MAX_ATTEMPTS_API_ENTREPRISE_JOBS).to_i
  end

  attr_reader :etablissement

  def find_etablissement(etablissement_id)
    @etablissement = Etablissement.find(etablissement_id)
  end
end
