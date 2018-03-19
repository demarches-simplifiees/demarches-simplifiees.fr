class SIRETService
  def self.fetch(siret, dossier = nil)
    procedure_id = dossier&.procedure_id

    etablissement_params = ApiEntreprise::EtablissementAdapter.new(siret, procedure_id).to_params
    entreprise_params = ApiEntreprise::EntrepriseAdapter.new(siren(siret), procedure_id).to_params

    if etablissement_params.present? && entreprise_params.present?
      association_params = ApiEntreprise::RNAAdapter.new(siret, procedure_id).to_params
      exercices_array = ApiEntreprise::ExercicesAdapter.new(siret, procedure_id).to_array

      params = etablissement_params
        .merge(entreprise_params.map { |k, v| ["entreprise_#{k}", v] }.to_h)
        .merge(association_params&.map { |k, v| ["association_#{k}", v] }.to_h)
        .merge(exercices_attributes: exercices_array)

      # This is to fill legacy models and relationships
      if dossier.present?
        params.merge(
          entreprise_attributes: entreprise_params
            .merge({
              dossier: dossier,
              rna_information_attributes: association_params
            }.compact)
        )
      else
        params
      end
    end
  end

  def self.siren(siret)
    siret[0..8]
  end
end
