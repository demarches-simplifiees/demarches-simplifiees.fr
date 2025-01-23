# frozen_string_literal: true

module SiretChampEtablissementFetchableConcern
  extend ActiveSupport::Concern

  attr_reader :etablissement_fetch_error_key

  def fetch_etablissement!(siret, user)
    return clear_etablissement!(:empty) if siret.empty?
    return clear_etablissement!(:invalid_length) if invalid_because?(siret, :length) # i18n-tasks-use t('errors.messages.siret.length')
    return clear_etablissement!(:invalid_checksum) if invalid_because?(siret, :checksum) # i18n-tasks-use t('errors.messages.siret.checksum')
    return clear_etablissement!(:not_found) unless (etablissement = APIEntrepriseService.create_etablissement(self, siret, user&.id)) # i18n-tasks-use t('errors.messages.siret.not_found')

    update!(etablissement:)
  rescue APIEntreprise::API::Error, APIEntrepriseToken::TokenError => error
    if APIEntrepriseService.service_unavailable_error?(error, target: :insee)
      update!(
        etablissement: APIEntrepriseService.create_etablissement_as_degraded_mode(self, siret, user.id)
      )
      @etablissement_fetch_error_key = :api_entreprise_down
      false
    else
      Sentry.capture_exception(error, extra: { dossier_id:, siret: })
      clear_etablissement!(:network_error) # i18n-tasks-use t('errors.messages.siret.network_error')
    end
  end

  private

  def clear_etablissement!(error_key)
    @etablissement_fetch_error_key = error_key

    etablissement_to_destroy = etablissement
    update!(etablissement: nil)
    etablissement_to_destroy&.destroy

    false
  end

  def invalid_because?(siret, criteria)
    validatable_siret = Siret.new(siret: siret)
    return false if validatable_siret.valid?

    validatable_siret.errors.details[:siret].any? && validatable_siret.errors.details[:siret].first[:error] == criteria
  end
end
