class ApiEntreprise::AssociationJob < ApplicationJob
  def perform(etablissement_id, procedure_id)
    etablissement = Etablissement.find(etablissement_id)
    etablissement_params = ApiEntreprise::RNAAdapter.new(etablissement.siret, procedure_id).to_params
    etablissement.update!(etablissement_params)
  end
end
