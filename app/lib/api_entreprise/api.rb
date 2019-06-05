class ApiEntreprise::API
  ENTREPRISE_RESOURCE_NAME = "entreprises"
  ETABLISSEMENT_RESOURCE_NAME = "etablissements"
  EXERCICES_RESOURCE_NAME = "exercices"
  RNA_RESOURCE_NAME = "associations"

  TIMEOUT = 15

  def self.entreprise(siren, procedure_id)
    call(ENTREPRISE_RESOURCE_NAME, siren, procedure_id)
  end

  def self.etablissement(siret, procedure_id)
    call(ETABLISSEMENT_RESOURCE_NAME, siret, procedure_id)
  end

  def self.exercices(siret, procedure_id)
    call(EXERCICES_RESOURCE_NAME, siret, procedure_id)
  end

  def self.rna(siret, procedure_id)
    call(RNA_RESOURCE_NAME, siret, procedure_id)
  end

  private

  def self.call(resource_name, siret_or_siren, procedure_id)
    url = url(resource_name, siret_or_siren)
    params = params(siret_or_siren, procedure_id)

    response = Typhoeus.get(url,
      params: params,
      timeout: TIMEOUT)

    if response.success?
      JSON.parse(response.body, symbolize_names: true)
    elsif response.code == 404 || response.code == 422
      raise RestClient::ResourceNotFound
    else
      raise RestClient::RequestFailed
    end
  end

  def self.url(resource_name, siret_or_siren)
    base_url = [API_ENTREPRISE_URL, resource_name, siret_or_siren].join("/")

    if Flipflop.insee_api_v3?
      base_url += "?with_insee_v3=true"
    end

    base_url
  end

  def self.params(siret_or_siren, procedure_id)
    {
      context: "demarches-simplifiees.fr",
      recipient: siret_or_siren,
      object: "procedure_id: #{procedure_id}",
      token: token
    }
  end

  def self.token
    Rails.application.secrets.api_entreprise[:key]
  end
end
