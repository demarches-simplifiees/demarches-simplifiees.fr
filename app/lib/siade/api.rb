class SIADE::API
  class << self
    attr_accessor :token
  end

  def initialize
  end

  def self.entreprise(siren, procedure_id)
    endpoint = "/v2/entreprises/#{siren}"
    call(endpoint, siren, procedure_id)
  end

  def self.etablissement(siret, procedure_id)
    endpoint = "/v2/etablissements/#{siret}"
    call(endpoint, siret, procedure_id)
  end

  def self.exercices(siret, procedure_id)
    endpoint = "/v2/exercices/#{siret}"
    call(endpoint, siret, procedure_id)
  end

  def self.rna(siret, procedure_id)
    endpoint = "/v2/associations/#{siret}"
    call(endpoint, siret, procedure_id)
  end

  def self.call(url, siret_or_siren, procedure_id)
    params = mandatory_params(siret_or_siren, procedure_id)
    params[:token] = SIADETOKEN

    verify_ssl_mode = OpenSSL::SSL::VERIFY_NONE

    RestClient::Resource.new(
      base_url + url,
      verify_ssl: verify_ssl_mode
    ).get(params: params)
  end

  def self.mandatory_params(siret_or_siren, procedure_id)
    {
      context: "demarches-simplifiees.fr",
      recipient: siret_or_siren,
      object: "procedure_id: #{procedure_id}"
    }
  end

  def self.base_url
    SIADEURL
  end
end
