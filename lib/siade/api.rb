class SIADE::API
  class << self
    attr_accessor :token
  end

  def initialize
  end

  def self.entreprise(siren)
    endpoint = "/api/v1/entreprises/#{siren}"
    call(base_url + endpoint)
  end

  def self.etablissement(siret)
    endpoint = "/api/v1/etablissements/#{siret}"
    call(base_url + endpoint)
  end

  def self.exercices(siret)
    endpoint = "/api/v1/etablissements/exercices/#{siret}"
    call(base_url + endpoint)
  end

  def self.rna(siret)
    endpoint = "/api/v1/associations/#{siret}"
    call(base_url + endpoint)
  end

  def self.call(url, params = {})
    params.merge!(token: SIADETOKEN)

    verify_ssl_mode = OpenSSL::SSL::VERIFY_NONE

    RestClient::Resource.new(
      url,
      verify_ssl: verify_ssl_mode
    ).get(params: params)
  end

  def self.base_url
    if Rails.env.production?
      'https://apientreprise.fr'
    else
      'https://api-dev.apientreprise.fr'
    end
  end
end
