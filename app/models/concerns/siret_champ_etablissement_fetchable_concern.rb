module SiretChampEtablissementFetchableConcern
  extend ActiveSupport::Concern

  attr_reader :etablissement_fetch_error_key

  def fetch_etablissement!(siret, user)
    return clear_etablissement!(:empty) if siret.empty?
    return clear_etablissement!(:invalid) unless Siret.new(siret: siret).valid? # i18n-tasks-use t('errors.messages.invalid_siret')
    return clear_etablissement!(:not_found) unless (etablissement = APIEntrepriseService.create_etablissement(self, siret, user&.id)) # i18n-tasks-use t('errors.messages.siret_not_found')

    update!(value: siret, etablissement: etablissement)
  rescue => error
    if error.try(:network_error?) && !APIEntrepriseService.api_up?
      # TODO: notify ops
      update!(
        value: siret,
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
end
