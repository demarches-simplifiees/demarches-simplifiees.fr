class ApiEntreprise::AttestationFiscaleAdapter < ApiEntreprise::Adapter
  def initialize(siret, procedure_id, user_id)
    @siret = siret
    @procedure_id = procedure_id
    @user_id = user_id
  end

  private

  def get_resource
    ApiEntreprise::API.attestation_fiscale(siren, @procedure_id, @user_id)
  end

  def process_params
    if data_source[:url].present?
      {
        entreprise_attestation_fiscale_url: data_source[:url]
      }
    else
      {}
    end
  end
end
