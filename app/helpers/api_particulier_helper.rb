module APIParticulierHelper
  def api_particulier_job_exception_reasons(dossier)
    permitted_classes = APIParticulier::Error::HttpError.descendants + [APIParticulier::Entities::Error]

    reasons = dossier.api_particulier_job_exceptions.map do |exception|
      http_error = Psych.safe_load(exception, permitted_classes: permitted_classes)
      http_error.error.reason
    rescue Psych::SyntaxError, Psych::DisallowedClass
      exception.inspect
    end

    simple_format(reasons.join('\n'))
  end

  def api_particulier_scopes(procedure)
    scopes = procedure.api_particulier_scopes
    sources = procedure.api_particulier_sources
    check_scope_sources_service = APIParticulier::Services::CheckScopeSources.new(scopes, sources)

    origins = scopes
      .keep_if { |scope| check_scope_sources_service.mandatory?(APIParticulier::Types::Scope[scope]) }
      .map { |scope| scope.split('_').first }

    origins.uniq.map { |origin| I18n.t(origin, scope: "api_particulier.types") }.to_sentence
  end
end
