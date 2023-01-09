module SiretChampEtablissementFetchableConcern
  extend ActiveSupport::Concern

  def fetch_etablissement!(siret, user)
    return clear if siret.empty?
    return clear(error: :invalid) unless Siret.new(siret: siret).valid? # i18n-tasks-use t('errors.messages.invalid_siret')
    return clear(error: :not_found) unless (etablissement = APIEntrepriseService.create_etablissement(self, siret, user.id)) # i18n-tasks-use t('errors.messages.siret_not_found')

    return update_etablissement!(etablissement)
  rescue => error
    if error.try(:network_error?) && !APIEntrepriseService.api_up?
      # TODO: notify ops
      etablissement = APIEntrepriseService.create_etablissement_as_degraded_mode(self, siret, user.id)
      return update_etablissement!(etablissement, error: :api_entreprise_down)
    else
      Sentry.capture_exception(error, extra: { dossier_id: dossier_id, siret: siret })
      return clear(error: :network_error) # i18n-tasks-use t('errors.messages.siret_network_error')
    end
  end

  private

  def update_etablissement!(etablissement, error: nil)
    update!(value: etablissement.siret, etablissement: etablissement)
    error.presence || etablissement.siret
  end

  def clear(error: nil)
    etablissement_to_destroy = etablissement
    update!(value: '', etablissement: nil)
    etablissement_to_destroy&.destroy
    error.presence
  end
end
