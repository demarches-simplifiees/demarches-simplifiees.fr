# frozen_string_literal: true

class Champs::SiretChamp < Champ
  include Dry::Monads[:result]
  validate :validate_etablissement, if: :validate_champ_value?
  normalizes :external_id, with: -> siret { siret.gsub(/[[:space:]]/, "") }

  def uses_external_data?
    true
  end

  # TODO: remove after T20251029backfillChampSiretExternalStateTask
  def external_id
    idle? && etablissement_id.present? ? value : super
  end

  def after_reset_external_data(opts = {})
    super(etablissement_id: nil, prefilled: false, value: nil)
  end

  def update_external_data!(data:)
    update(etablissement: data[:etablissement], value: external_id)
  end

  def ready_for_external_call?
    Siret.new(siret: external_id).valid?
  end

  def fetch_external_data
    etablissement = APIEntrepriseService.create_etablissement(self, external_id.delete(" "), dossier.user&.id)
    if etablissement.blank?
      Failure(retryable: false, reason: Excon::Error::NotFound.new('NotFound'), code: 404)
    else
      Success(etablissement:)
    end
  rescue APIEntrepriseToken::TokenError
    Failure(retryable: true, reason: Excon::Error::Unauthorized.new('wrong token'), code: 401)
  rescue APIEntreprise::API::Error => error
    if APIEntrepriseService.service_unavailable_error?(error, target: :insee)
      update!(
        etablissement: APIEntrepriseService.create_etablissement_as_degraded_mode(self, external_id, dossier.user&.id)
      )
      Failure(retryable: true, reason: Excon::Error::ServiceUnavailable.new('APIDown'), code: 503)
    else
      Sentry.capture_exception(error, extra: { dossier_id:, siret: external_id })
      Failure(retryable: false, reason: Excon::Error::InternalServerError.new('API crashed'), code: 500)
    end
  end

  def search_terms
    etablissement.present? ? etablissement.search_terms : [value]
  end

  private

  # We want to validate if SIRET really exists
  # It's valid when an etablissement have been created in turbo with SIRET controller
  # When API Entreprise is down, user won't be stuck because
  # SIRET controller creates an etablissement in degraded mode
  def validate_etablissement
    return if external_id.blank?
    return if etablissement.present?
    return if pending?

    validator = ActiveModel::Validations::SiretValidator.new(attributes: { value: true })

    # siret may have been formatted with spaces
    validator.validate_each(self, :external_id, external_id.gsub(/[[:space:]]/, ""))

    if errors.empty?
      errors.add(:external_id, :not_found)
    end
  end
end
