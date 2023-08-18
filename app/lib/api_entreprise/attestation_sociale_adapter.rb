class APIEntreprise::AttestationSocialeAdapter < APIEntreprise::Adapter
  def initialize(siret, procedure_id)
    @siret = siret
    @procedure_id = procedure_id
  end

  private

  def get_resource
    api(@procedure_id).attestation_sociale(siren)
  end

  def process_params
    if data_source[:data] && data_source[:data][:document_url].present?
      {
        entreprise_attestation_sociale_url: data_source[:data][:document_url]
      }
    else
      {}
    end
  end
end
