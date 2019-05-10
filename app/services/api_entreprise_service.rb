class ApiEntrepriseService
  # Retrieve all informations we can get about a SIRET.
  #
  # Returns nil if the SIRET is unknown; and nested params
  # suitable for being saved into a Etablissement object otherwise.
  #
  # Raises a RestClient::RequestFailed exception on transcient errors
  # (timeout, 5XX HTTP error code, etc.)
  def self.get_etablissement_params_for_siret(siret, procedure_id)
    if siret.length == 6
      tahiti_params = ApiEntreprise::PfEtablissementAdapter.new(siret, procedure_id).to_params
      if tahiti_params.present?
        return tahiti_params
      end
    end
    etablissement_params = ApiEntreprise::EtablissementAdapter.new(siret, procedure_id).to_params
    entreprise_params = ApiEntreprise::EntrepriseAdapter.new(siret, procedure_id).to_params

    if etablissement_params.present? && entreprise_params.present?
      begin
        association_params = ApiEntreprise::RNAAdapter.new(siret, procedure_id).to_params
        etablissement_params.merge!(association_params)
      rescue RestClient::RequestFailed
      end

      begin
        exercices_params = ApiEntreprise::ExercicesAdapter.new(siret, procedure_id).to_params
        etablissement_params.merge!(exercices_params)
      rescue RestClient::RequestFailed
      end

      etablissement_params.merge(entreprise_params)
    end
  end
end
