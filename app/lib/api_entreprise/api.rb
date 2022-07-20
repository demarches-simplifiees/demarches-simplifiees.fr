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

  attr_reader :procedure
  attr_accessor :token

  def initialize(procedure_id = nil)
    return if procedure_id.blank?

    @procedure = Procedure.find(procedure_id)
    @token = @procedure.api_entreprise_token
  end

  def entreprise(siren)
    call_with_siret(ENTREPRISE_RESOURCE_NAME, siren)
  end

  def etablissement(siret)
    call_with_siret(ETABLISSEMENT_RESOURCE_NAME, siret)
  end

  def exercices(siret)
    call_with_siret(EXERCICES_RESOURCE_NAME, siret)
  end

  def rna(siret)
    call_with_siret(RNA_RESOURCE_NAME, siret)
  end

  def effectifs(siren, annee, mois)
    endpoint = [EFFECTIFS_RESOURCE_NAME, annee, mois, "entreprise"].join('/')
    call_with_siret(endpoint, siren)
  end

  def effectifs_annuels(siren)
    call_with_siret(EFFECTIFS_ANNUELS_RESOURCE_NAME, siren)
  end

  def attestation_sociale(siren)
    return unless procedure.api_entreprise_role?("attestations_sociales")

    call_with_siret(ATTESTATION_SOCIALE_RESOURCE_NAME, siren)
  end

  def attestation_fiscale(siren, user_id)
    return unless procedure.api_entreprise_role?("attestations_fiscales")

    call_with_siret(ATTESTATION_FISCALE_RESOURCE_NAME, siren, user_id: user_id)
  end

  def bilans_bdf(siren)
    return unless procedure.api_entreprise_role?("bilans_entreprise_bdf")

    call_with_siret(BILANS_BDF_RESOURCE_NAME, siren)
  end

  def privileges
    url = make_url(PRIVILEGES_RESOURCE_NAME)
    call(url)
  end

  private

  def call_with_siret(resource_name, siret_or_siren, user_id: nil)
    url = make_url(resource_name, siret_or_siren)

    params = build_params(user_id)

    call(url, params)
  end

  def call(url, params = nil)
    verify_token!

    # this is a poor man throttling
    # the idea is to queue api entreprise job on 1 worker
    # and add a delay between each call
    # example: API_ENTREPRISE_DELAY=1 => 60 rpm max
    if api_entreprise_delay != 0.0
      sleep api_entreprise_delay
    end

    response = Typhoeus.get(url,
      headers: { Authorization: "Bearer #{token}" },
      params: params,
      timeout: TIMEOUT)

    handle_response(response)
  end

  def handle_response(response)
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

  def make_url(resource_name, siret_or_siren = nil)
    [API_ENTREPRISE_URL, resource_name, siret_or_siren].compact.join("/")
  end

  def build_params(user_id)
    params = base_params

    params[:object] = "procedure_id: #{procedure.id}" if procedure.present?
    params[:user_id] = user_id if user_id.present?

    params
  end

  def base_params
    # rubocop:disable DS/ApplicationName
    {
      context: "demarches-simplifiees.fr",
      recipient: ENV.fetch('API_ENTREPRISE_DEFAULT_SIRET'),
      non_diffusables: true
    }
    # rubocop:enable DS/ApplicationName
  end

  def api_entreprise_delay
    ENV.fetch("API_ENTREPRISE_DELAY", DEFAULT_API_ENTREPRISE_DELAY).to_f
  end

  def verify_token!
    return unless APIEntrepriseToken.new(token).expired?

    raise APIEntrepriseToken::TokenError, I18n.t("api_entreprise.errors.token_expired")
  end
end
