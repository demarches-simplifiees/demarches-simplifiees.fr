# frozen_string_literal: true

class APIEntreprise::AssociationJob < APIEntreprise::Job
  def perform(etablissement_id, procedure_id)
    find_etablissement(etablissement_id)
    etablissement_params = APIEntreprise::RNAAdapter.new(etablissement.siret, procedure_id, true).to_params
    etablissement.update!(etablissement_params)
  end
end
