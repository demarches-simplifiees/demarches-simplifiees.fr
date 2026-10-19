# frozen_string_literal: true

module APIEntrepriseExternalDataConcern
  extend ActiveSupport::Concern

  include Dry::Monads[:result]

  GLOBAL_TOKEN_ALERT_EVERY = 1.hour

  private

  def ready_for_external_retry? = procedure.api_entreprise_token_usable?

  def fetch_sirene_etablissement(siret)
    return token_unusable_failure if !procedure.api_entreprise_token_usable?

    case APIEntreprise::Sirene.fetch_etablissement(siret, procedure.id)
    in Success(etablissement)
      procedure.forget_api_entreprise_token_rejection!
      Success(etablissement:)
    in Failure => failure
      api_entreprise_failure(failure)
    end
  end

  # No call goes out, so the credentials branch of api_entreprise_failure would
  # never alert: the reason is only readable from the token itself.
  def token_unusable_failure
    alert_global_token_refused(procedure.api_entreprise_token.unusable_reason, 401) if !procedure.specific_api_entreprise_token?

    degraded_failure(:token_rejected, 401)
  end

  # What the usager cannot fix must not block them: a provider outage and our
  # own credentials both degrade, only their identifier fails.
  def api_entreprise_failure(result)
    case result
    in Failure(retryable: true, type:, code:, **)
      degraded_failure(type, code)
    in Failure(retryable: false, type:, code:, **) if code.in?(ExternalDataException::CREDENTIALS_CODES)
      record_credentials_failure(type, code)
      degraded_failure(type, code)
    in Failure(retryable: false, type:, code:, **)
      # a non-diffusible SIRET (451) is an expected answer, not a bug
      Failure(retryable: false, error: StandardError.new("API Entreprise: #{type}"), code:, report: code != 451)
    end
  end

  def degraded_failure(type, code)
    Failure(degraded: true, error: StandardError.new("API Entreprise: #{type}"), code:)
  end

  # The administrateur can act on a token of their own; on the instance one,
  # only operations can — and only if we tell them.
  def record_credentials_failure(type, code)
    if procedure.specific_api_entreprise_token?
      procedure.mark_api_entreprise_token_as_rejected!
    else
      alert_global_token_refused(type, code)
    end
  end

  # Every dossier of every procedure hits the same wall: one alert per hour is
  # enough. The type says what to do — renew the key, fill the env var, or ask
  # for the missing scope.
  def alert_global_token_refused(type, code)
    key = "api_entreprise:global_token_refused:#{type}"
    return if !Rails.cache.write(key, true, expires_in: GLOBAL_TOKEN_ALERT_EVERY, unless_exist: true)

    Sentry.capture_message("global API Entreprise token is refused ! DO SOMETHING ! TTU !",
      level: :error, tags: { procedure: procedure.id }, extra: { type:, code: })
  end
end
