# frozen_string_literal: true

class APIEntreprise::Job < ApplicationJob
  class RetryableError < StandardError; end
  class ProviderDownError < RetryableError; end

  # The upstream provider behind API Entreprise failed in a way a retry may fix
  # (5xx, timeout); reported once the Sidekiq attempt threshold is reached.
  class UpstreamError < StandardError
    include SentryFingerprint::ProviderOutage

    def initialize(message, provider:)
      @provider = provider
      super(message)
    end
  end

  include Dry::Monads[:result]

  queue_as :default

  use_sidekiq_retry(report_after_attempts: 8)

  # Rate limit pool per job class (matches API Entreprise pools).
  # Jobs not listed here default to DEFAULT_POOL (250).
  POOL_BY_JOB = {
    'AttestationFiscaleJob' => 5,
    'EffectifsJob' => 50,
    'EffectifsAnnuelsJob' => 50,
    'AttestationSocialeJob' => 100,
  }.freeze

  # Maps each job to its API Entreprise provider ping key.
  # Used by before_perform to skip jobs when provider is down.
  # See https://entreprise.api.gouv.fr/developpeurs#surveillance-etat-fournisseurs
  PING_KEY_BY_JOB = {
    'ExtraitKbisJob' => APIEntreprise::HealthChecker::PROVIDERS[:infogreffe_rcs],
    'TvaJob' => APIEntreprise::HealthChecker::PROVIDERS[:dgfip_numero_tva],
    'AssociationJob' => APIEntreprise::HealthChecker::PROVIDERS[:djepva_association],
    'ExercicesJob' => APIEntreprise::HealthChecker::PROVIDERS[:dgfip_chiffre_affaires],
    'EffectifsJob' => APIEntreprise::HealthChecker::PROVIDERS[:gip_mds_effectifs],
    'EffectifsAnnuelsJob' => APIEntreprise::HealthChecker::PROVIDERS[:gip_mds_effectifs],
    'AttestationSocialeJob' => APIEntreprise::HealthChecker::PROVIDERS[:urssaf_attestation_sociale],
    'AttestationFiscaleJob' => APIEntreprise::HealthChecker::PROVIDERS[:dgfip_attestation_fiscale],
    'BilansBdfJob' => APIEntreprise::HealthChecker::PROVIDERS[:banque_de_france_bilans],
    'ServiceJob' => APIEntreprise::HealthChecker::PROVIDERS[:insee_sirene],
  }.freeze

  # If by the time the job runs the Etablissement has been deleted, ignore the job
  discard_on ActiveRecord::RecordNotFound

  # Skip job if provider is known to be down, then check rate limit.
  # Health check first (cheap Redis read), rate limiter second.
  before_perform do
    ping_key = ping_key_for_job
    if ping_key && !APIEntreprise::HealthChecker.provider_up?(ping_key)
      raise ProviderDownError, "#{self.class.name}: provider #{ping_key} is down, retrying later"
    end

    pool = api_pool
    if APIEntreprise::RateLimiter.throttled?(pool)
      raise RetryableError, "#{self.class.name}: rate limited (pool #{pool}), retrying later"
    end
  end

  def log_job_exception(exception)
    if etablissement.present?
      if etablissement.dossier.present?
        etablissement.dossier.log_api_entreprise_job_exception(exception)
      elsif etablissement.champ_data.present?
        etablissement.champ_data.save_additional_job_exception(exception, :unkonwn)
      end
    end
  end

  attr_reader :etablissement

  def find_etablissement(etablissement_id)
    @etablissement = Etablissement.find(etablissement_id)
  end

  # Centralizes monad unwrap for adapter results.
  # Success(params) with data → yields params to block
  # Success({}) → no-op (resource not found, nothing to update)
  # Failure(retryable: true) → re-raises to trigger job retry
  # Failure(retryable: false) → logs and no-op (forbidden, 451, etc.)
  def with_adapter(adapter)
    result = adapter.to_params

    case result
    in Success(params) if params.present?
      yield params
    in Success
      nil
    in Failure(retryable: true, type: :rate_limited, code:, **)
      raise RetryableError, "#{self.class.name}: rate limited by API (pool #{api_pool}), retrying later"
    in Failure(retryable: true, type:, code:, raw_response:, **)
      raise UpstreamError.new(format_error(type, code, raw_response), provider: self.class.name)
    in Failure(retryable: false, type:, code:, **)
      Rails.logger.info("APIEntreprise non-retryable failure: type=#{type} code=#{code}")
      nil
    else
      raise "Unexpected adapter result: #{result.inspect}"
    end
  end

  # Pool derived from job class name via POOL_BY_JOB.
  def api_pool
    POOL_BY_JOB.fetch(self.class.name.demodulize, APIEntreprise::API::DEFAULT_POOL)
  end

  # Ping key derived from job class name via PING_KEY_BY_JOB.
  # Returns nil for unknown jobs (fail-open).
  def ping_key_for_job
    PING_KEY_BY_JOB[self.class.name.demodulize]
  end

  private

  def format_error(type, code, raw_response)
    message = "API Entreprise error: type=#{type} code=#{code}"
    if raw_response.present?
      uri = URI.parse(raw_response.effective_url) rescue nil
      message += " url=#{uri&.host}#{uri&.path} body=#{raw_response.body.truncate(500)}"
    end
    message
  end
end
