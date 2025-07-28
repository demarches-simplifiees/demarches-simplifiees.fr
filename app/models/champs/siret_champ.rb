# frozen_string_literal: true

class Champs::SiretChamp < Champ
  include SiretChampEtablissementFetchableConcern

  validate :validate_etablissement, if: :validate_champ_value?

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
