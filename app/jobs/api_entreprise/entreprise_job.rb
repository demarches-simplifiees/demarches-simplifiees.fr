class ApiEntreprise::EntrepriseJob < ApiEntreprise::Job
  def perform(etablissement_id, procedure_id)
    find_etablissement(etablissement_id)
    etablissement_params = ApiEntreprise::EntrepriseAdapter.new(etablissement.siret, procedure_id).to_params
    etablissement.update!(etablissement_params)
  end
end
