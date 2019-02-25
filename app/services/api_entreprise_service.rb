class ApiEntrepriseService
  def self.get_etablissement_params_for_siret(siret, procedure_id)
    etablissement_params = ApiEntreprise::EtablissementAdapter.new(siret, procedure_id).to_params
    entreprise_params = ApiEntreprise::EntrepriseAdapter.new(siret, procedure_id).to_params

    if etablissement_params.present? && entreprise_params.present?
      association_params = ApiEntreprise::RNAAdapter.new(siret, procedure_id).to_params
      exercices_params = ApiEntreprise::ExercicesAdapter.new(siret, procedure_id).to_params

      etablissement_params.merge(
        entreprise_params,
        association_params,
        exercices_params
      )
    end
  end
end
