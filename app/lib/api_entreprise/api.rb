class ApiEntreprise::API
  ENTREPRISE_RESOURCE_NAME = "entreprises"
  ETABLISSEMENT_RESOURCE_NAME = "etablissements"
  EXERCICES_RESOURCE_NAME = "exercices"
  RNA_RESOURCE_NAME = "associations"
  EFFECTIFS_RESOURCE_NAME = "effectifs_mensuels_acoss_covid"
  EFFECTIFS_ANNUELS_RESOURCE_NAME = "effectifs_annuels_acoss_covid"
  ATTESTATION_SOCIALE_RESOURCE_NAME = "attestations_sociales_acoss"
  ATTESTATION_FISCALE_RESOURCE_NAME = "attestations_fiscales_dgfip"
  BILANS_BDF_RESOURCE_NAME = "bilans_entreprises_bdf"
  PRIVILEGES_RESOURCE_NAME = "privileges"

  TIMEOUT = 20

  class ResourceNotFound < StandardError
  end

  class RequestFailed < StandardError
  end

  class BadFormatRequest < StandardError
  end

  class BadGateway < StandardError
  end

  class ServiceUnavailable < StandardError
  end

  class TimedOut < StandardError
  end

  def self.entreprise(siren, procedure_id)
    call_with_siret(ENTREPRISE_RESOURCE_NAME, siren, procedure_id)
  end

  def self.etablissement(siret, procedure_id)
    call_with_siret(ETABLISSEMENT_RESOURCE_NAME, siret, procedure_id)
  end

  def self.exercices(siret, procedure_id)
    call_with_siret(EXERCICES_RESOURCE_NAME, siret, procedure_id)
  end

  def self.rna(siret, procedure_id)
    call_with_siret(RNA_RESOURCE_NAME, siret, procedure_id)
  end

  def self.effectifs(siren, procedure_id, annee, mois)
    endpoint = [EFFECTIFS_RESOURCE_NAME, annee, mois, "entreprise"].join('/')
    call_with_siret(endpoint, siren, procedure_id)
  end

  def self.effectifs_annuels(siren, procedure_id)
    call_with_siret(EFFECTIFS_ANNUELS_RESOURCE_NAME, siren, procedure_id)
  end

  def self.attestation_sociale(siren, procedure_id)
    procedure = Procedure.find(procedure_id)
    call_with_siret(ATTESTATION_SOCIALE_RESOURCE_NAME, siren, procedure_id) if procedure.api_entreprise_role?("attestations_sociales")
  end

  def self.attestation_fiscale(siren, procedure_id, user_id)
    procedure = Procedure.find(procedure_id)
    call_with_siret(ATTESTATION_FISCALE_RESOURCE_NAME, siren, procedure_id, user_id) if procedure.api_entreprise_role?("attestations_fiscales")
  end

  def self.bilans_bdf(siren, procedure_id)
    procedure = Procedure.find(procedure_id)
    call_with_siret(BILANS_BDF_RESOURCE_NAME, siren, procedure_id) if procedure.api_entreprise_role?("bilans_entreprise_bdf")
  end

  def self.privileges(token)
    call_with_token(PRIVILEGES_RESOURCE_NAME, token)
  end

  private

  def self.call_with_token(resource_name, token)
    url = "#{API_ENTREPRISE_URL}/privileges?token=#{token}"
    response = Typhoeus.get(url,
      timeout: TIMEOUT)

    if response.success?
      JSON.parse(response.body, symbolize_names: true)
    else
      raise RequestFailed, "HTTP Error Code: #{response.code} for #{url}\nheaders: #{response.headers}\nbody: #{response.body}"
    end
  end

  def self.call_with_siret(resource_name, siret_or_siren, procedure_id, user_id = nil)
    return if ApiEntrepriseToken.new(token_for_procedure(procedure_id)).expired?
    url = url(resource_name, siret_or_siren)
    params = params(siret_or_siren, procedure_id, user_id)

    response = Typhoeus.get(url,
      params: params,
      timeout: TIMEOUT)

    if response.success?
      JSON.parse(response.body, symbolize_names: true)
    elsif response.code&.between?(401, 499)
      raise ResourceNotFound, "url: #{url}"
    elsif response.code == 400
      raise BadFormatRequest, "url: #{url}"
    elsif response.code == 502
      raise	BadGateway, "url: #{url}"
    elsif response.code == 503
      raise ServiceUnavailable, "url: #{url}"
    elsif response.timed_out?
      raise TimedOut, "url: #{url}"
    else
      raise RequestFailed,
        <<~TEXT
          HTTP Error Code: #{response.code} for #{url}
          headers: #{response.headers}
          body: #{response.body}
          curl message: #{response.return_message}
        TEXT
    end
  end

  def self.url(resource_name, siret_or_siren)
    base_url = [API_ENTREPRISE_URL, resource_name, siret_or_siren].join("/")

    if Flipper.enabled?(:insee_api_v3)
      base_url += "?with_insee_v3=true"
    end

    base_url
  end

  def self.params(siret_or_siren, procedure_id, user_id)
    # rubocop:disable DS/ApplicationName
    params = {
      context: "demarches-simplifiees.fr",
      recipient: siret_or_siren,
      object: "procedure_id: #{procedure_id}",
      non_diffusables: true,
      token: token_for_procedure(procedure_id)
    }
    # rubocop:enable DS/ApplicationName
    params[:user_id] = user_id if user_id.present?
    params
  end

  def self.token_for_procedure(procedure_id)
    procedure = Procedure.find(procedure_id)
    procedure.api_entreprise_token
  end
end
