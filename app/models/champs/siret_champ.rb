# frozen_string_literal: true

class Champs::SiretChamp < Champ
  include Dry::Monads[:result]
  validate :validate_etablissement, if: :validate_champ_value?

  def uses_external_data?
    true
  end

  def after_reset_external_data
    super
    update_columns(prefilled: false, value: nil, etablissement_id: nil)
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
      Failure(retryable: false, reason: :not_found, code: 404)
    else
      Success(etablissement:)
    end
  rescue APIEntreprise::API::Error, APIEntrepriseToken::TokenError => error
    if APIEntrepriseService.service_unavailable_error?(error, target: :insee)
      update!(
        etablissement: APIEntrepriseService.create_etablissement_as_degraded_mode(self, external_id, dossier.user&.id)
      )
      Failure(retryable: true, reason: :api_down, code: 503)
    else
      Sentry.capture_exception(error, extra: { dossier_id:, siret: external_id })
      Failure(retryable: false, reason: :api_down, code: 503)
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
    return if value.blank?
    return if etablissement.present?

    validator = ActiveModel::Validations::SiretValidator.new(attributes: { value: true })

    # siret may have been formatted with spaces
    validator.validate_each(self, :value, value.gsub(/[[:space:]]/, ""))

    if errors.empty?
      errors.add(:value, :not_found)
    end
  end
end
