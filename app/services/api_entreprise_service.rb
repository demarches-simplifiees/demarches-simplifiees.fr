class ApiEntrepriseService
  def self.get_etablissement_params_for_siret(siret, procedure_id, dossier = nil)
    etablissement_params = ApiEntreprise::EtablissementAdapter.new(siret, procedure_id).to_params
    entreprise_params = ApiEntreprise::EntrepriseAdapter.new(siret, procedure_id).to_params

    if etablissement_params.present? && entreprise_params.present?
      association_params = ApiEntreprise::RNAAdapter.new(siret, procedure_id).to_params
      exercices_params = ApiEntreprise::ExercicesAdapter.new(siret, procedure_id).to_params

      params = etablissement_params
        .merge(entreprise_params.transform_keys { |k| "entreprise_#{k}" })
        .merge(association_params.transform_keys { |k| "association_#{k}" })
        .merge(exercices_params)

      # This is to fill legacy models and relationships
      if dossier.present?
        handle_legacy_models!(params, entreprise_params, dossier, association_params)
      end

      params
    end
  end

  def self.handle_legacy_models!(params, entreprise_params, dossier, association_params)
    params[:entreprise_attributes] = entreprise_params.merge(
      {
        dossier: dossier,
        rna_information_attributes: association_params.presence
      }.compact
    )
  end
end
