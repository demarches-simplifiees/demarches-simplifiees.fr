# frozen_string_literal: true

class APIEntreprise::BilansBdfJob < APIEntreprise::Job
  def perform(etablissement_id, procedure_id)
    find_etablissement(etablissement_id)
    etablissement_params = APIEntreprise::BilansBdfAdapter.new(etablissement.siret, procedure_id).to_params
    etablissement.update!(etablissement_params)
  end
end
