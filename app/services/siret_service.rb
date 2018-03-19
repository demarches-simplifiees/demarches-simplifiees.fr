class SIRETService
  def self.fetch(siret, dossier = nil)
    etablissement_params = ApiEntreprise::EtablissementAdapter.new(siret, dossier&.procedure_id).to_params
    entreprise_params = ApiEntreprise::EntrepriseAdapter.new(siren(siret), dossier&.procedure_id).to_params

    if etablissement_params.present? && entreprise_params.present?
      association = ApiEntreprise::RNAAdapter.new(siret, dossier&.procedure_id)
      exercices = ApiEntreprise::ExercicesAdapter.new(siret, dossier&.procedure_id)

      params = etablissement_params
        .merge(entreprise_params.map { |k,v| ["entreprise_#{k}", v] }.to_h)
        .merge(association.to_params&.map { |k,v| ["association_#{k}", v] }.to_h)
        .merge(exercices_attributes: exercices.to_array)

      # This is to fill legacy models and relationships
      if dossier.present?
        return params.merge(
          entreprise_attributes: entreprise_params
            .merge({
              dossier: dossier,
              rna_information_attributes: association.to_params
            }.compact)
        )
      else
        return params
      end
    end
  end

  def self.siren(siret)
    siret[0..8]
  end
end
