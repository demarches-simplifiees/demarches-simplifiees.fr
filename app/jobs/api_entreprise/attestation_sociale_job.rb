class ApiEntreprise::AttestationSocialeJob < ApiEntreprise::Job
  def perform(etablissement_id, procedure_id)
    etablissement = Etablissement.find(etablissement_id)
    etablissement_params = ApiEntreprise::AttestationSocialeAdapter.new(etablissement.siret, procedure_id).to_params
    attestation_sociale_url = etablissement_params.delete(:entreprise_attestation_sociale_url)
    etablissement.upload_attestation_sociale(attestation_sociale_url) if attestation_sociale_url.present?
  end
end
