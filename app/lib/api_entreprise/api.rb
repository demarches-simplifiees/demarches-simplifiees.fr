class APIEntreprise::API
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
  DEFAULT_API_ENTREPRISE_DELAY = 0.0

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
    url = "#{API_ENTREPRISE_URL}/#{resource_name}"

    # this is a poor man throttling
    # the idea is to queue api entreprise job on 1 worker
    # and add a delay between each call
    # example: API_ENTREPRISE_DELAY=1 => 60 rpm max
    if api_entreprise_delay != 0.0
      sleep api_entreprise_delay
    end

    response = Typhoeus.get(url,
      headers: { Authorization: "Bearer #{token}" },
      timeout: TIMEOUT)

    if response.success?
      JSON.parse(response.body, symbolize_names: true)
    else
      raise RequestFailed.new(response)
    end
  end

  def self.call_with_siret(resource_name, siret_or_siren, procedure_id, user_id = nil)
    return if APIEntrepriseToken.new(token_for_procedure(procedure_id)).expired?
    url = url(resource_name, siret_or_siren)
    params = params(siret_or_siren, procedure_id, user_id)

    if api_entreprise_delay != 0.0
      sleep api_entreprise_delay
    end

    response = Typhoeus.get(url,
      headers: { Authorization: "Bearer #{token_for_procedure(procedure_id)}" },
      params: params,
      timeout: TIMEOUT)

    if response.success?
      JSON.parse(response.body, symbolize_names: true)
    elsif response.code&.between?(401, 499)
      raise Error::ResourceNotFound.new(response)
    elsif response.code == 400
      raise Error::BadFormatRequest.new(response)
    elsif response.code == 502
      raise	Error::BadGateway.new(response)
    elsif response.code == 503
      raise Error::ServiceUnavailable.new(response)
    elsif response.timed_out?
      raise Error::TimedOut.new(response)
    else
      raise Error::RequestFailed.new(response)
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
    params = {
      context: (FR_SITE).to_s,
      recipient: siret_or_siren,
      object: "procedure_id: #{procedure_id}",
      non_diffusables: true
    }

    params[:user_id] = user_id if user_id.present?
    params
  end

  def self.token_for_procedure(procedure_id)
    procedure = Procedure.find(procedure_id)
    procedure.api_entreprise_token
  end

  def self.api_entreprise_delay
    ENV.fetch("API_ENTREPRISE_DELAY", DEFAULT_API_ENTREPRISE_DELAY).to_f
  end
end
