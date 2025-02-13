# frozen_string_literal: true

module SiretChampEtablissementFetchableConcern
  extend ActiveSupport::Concern

  def fetch_etablissement!(siret, user)
    return clear_etablissement! if siret.empty?
    return clear_etablissement! if Siret.new(siret:).invalid?

    etablissement = APIEntrepriseService.create_etablissement(self, siret, user&.id)
    return clear_etablissement! if etablissement.blank?

    update!(etablissement:)
  rescue APIEntreprise::API::Error, APIEntrepriseToken::TokenError => error
    if APIEntrepriseService.service_unavailable_error?(error, target: :insee)
      update!(
        etablissement: APIEntrepriseService.create_etablissement_as_degraded_mode(self, siret, user.id)
      )
      false
    else
      Sentry.capture_exception(error, extra: { dossier_id:, siret: })
      clear_etablissement!
    end
  end

  private

  def clear_etablissement!
    etablissement_to_destroy = etablissement
    update!(etablissement: nil)
    etablissement_to_destroy&.destroy

    false
  end
end
