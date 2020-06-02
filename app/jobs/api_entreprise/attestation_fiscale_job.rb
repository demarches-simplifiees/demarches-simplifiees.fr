class ApiEntreprise::AttestationFiscaleJob < ApiEntreprise::Job
  def perform(etablissement_id, procedure_id, user_id)
    etablissement = Etablissement.find(etablissement_id)
    etablissement_params = ApiEntreprise::AttestationFiscaleAdapter.new(etablissement.siret, procedure_id, user_id).to_params
    attestation_fiscale_url = etablissement_params.delete(:entreprise_attestation_fiscale_url)
    etablissement.upload_attestation_fiscale(attestation_fiscale_url) if attestation_fiscale_url.present?
  end
end
