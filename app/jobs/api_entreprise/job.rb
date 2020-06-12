class ApiEntreprise::Job < ApplicationJob
  DEFAULT_MAX_ATTEMPTS_API_ENTREPRISE_JOBS = 5

  rescue_from(ApiEntreprise::API::ResourceNotFound) do |exception|
    error(self, exception)
  end

  rescue_from(ApiEntreprise::API::BadFormatRequest) do |exception|
    error(self, exception)
  end

  def max_attempts
    ENV[MAX_ATTEMPTS_API_ENTREPRISE_JOBS].to_i || DEFAULT_MAX_ATTEMPTS_API_ENTREPRISE_JOBS
  end
end
