# frozen_string_literal: true

class Champs::SiretChamp < Champ
  validate :validate_etablissement, if: :validate_champ_value?
  before_save :clear_previous_result, if: -> { external_id_changed? }

  def uses_external_data?
    true
  end

  def should_ui_auto_refresh?
    true
  end

  def clear_previous_result
    if etablissement.present?
      etablissement_to_destroy = etablissement
      update_column(:etablissement_id, nil)
      etablissement_to_destroy.destroy
    end
    self.value_json = nil
    self.value = nil
    self.prefilled = false
  end

  def external_data_present?
    etablissement.present?
  end

  def update_external_data!(data:)
    update(value: external_id)
  end

  def fetch_external_data
    fetch_etablissement!(external_id, dossier.user)
  end

  def search_terms
    etablissement.present? ? etablissement.search_terms : [value]
  end

  def fetch_etablissement!(siret, user)
    return clear_previous_result if siret.empty?
    return clear_previous_result if Siret.new(siret:).invalid?

    etablissement = APIEntrepriseService.create_etablissement(self, siret.delete(" "), user&.id)
    return clear_previous_result if etablissement.blank?

    update!(etablissement:)
  rescue APIEntreprise::API::Error, APIEntrepriseToken::TokenError => error
    if APIEntrepriseService.service_unavailable_error?(error, target: :insee)
      update!(
        etablissement: APIEntrepriseService.create_etablissement_as_degraded_mode(self, siret, user.id)
      )
      false
    else
      Sentry.capture_exception(error, extra: { dossier_id:, siret: })
      clear_previous_result
    end
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
