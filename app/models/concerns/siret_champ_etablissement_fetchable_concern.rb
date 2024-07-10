module SiretChampEtablissementFetchableConcern
  extend ActiveSupport::Concern

  attr_reader :etablissement_fetch_error_key, :other_etablissements

  def fetch_etablissement!(siret, user)
    return clear_etablissement!(:empty) if siret.empty?
    return clear_etablissement!(:invalid_length) if invalid_because?(siret, :length) # i18n-tasks-use t('errors.messages.invalid_siret_length')
    return clear_etablissement!(:invalid_checksum) if invalid_because?(siret, :checksum) # i18n-tasks-use t('errors.messages.invalid_siret_checksum')
    return clear_etablissement!(:not_found) unless (etablissement, @other_etablissements = APIEntrepriseService.create_etablissement(self, siret, user&.id)) # i18n-tasks-use t('errors.messages.siret_not_found')

    if @other_etablissements && other_etablissements.size > 1
      self.etablissement = etablissement
    else
      update!(etablissement: etablissement)
    end
  rescue => error
    if error.try(:network_error?) && !APIEntrepriseService.api_insee_up?
      # TODO: notify ops
      update!(
        etablissement: APIEntrepriseService.create_etablissement_as_degraded_mode(self, siret, user.id)
      )
      @etablissement_fetch_error_key = :api_entreprise_down
      false
    else
      Sentry.capture_exception(error, extra: { dossier_id: dossier_id, siret: siret })
      clear_etablissement!(:network_error) # i18n-tasks-use t('errors.messages.siret_network_error')
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
