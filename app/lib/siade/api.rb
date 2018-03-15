class SIADE::API
  class << self
    attr_accessor :token
  end

  ENTREPRISE_RESOURCE_NAME = "entreprises"
  ETABLISSEMENT_RESOURCE_NAME = "etablissements"
  EXERCICES_RESOURCE_NAME = "exercices"
  RNA_RESOURCE_NAME = "associations"

  def initialize
  end

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

  def self.call(resource_name, siret_or_siren, procedure_id)
    params = mandatory_params(siret_or_siren, procedure_id)
    params[:token] = SIADETOKEN

    verify_ssl_mode = OpenSSL::SSL::VERIFY_NONE

    RestClient::Resource.new(
      url(resource_name, siret_or_siren),
      verify_ssl: verify_ssl_mode
    ).get(params: params)
  end

  def self.url(resource_name, siret_or_siren)
    [SIADEURL, "v2", resource_name, siret_or_siren].join("/")
  end

  def self.mandatory_params(siret_or_siren, procedure_id)
    {
      context: "demarches-simplifiees.fr",
      recipient: siret_or_siren,
      object: "procedure_id: #{procedure_id}"
    }
  end
end
