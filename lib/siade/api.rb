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

  def self.call(url)
    verify_ssl_mode = OpenSSL::SSL::VERIFY_NONE

    RestClient::Resource.new(
      url,
      verify_ssl: verify_ssl_mode
    ).get(params: { token: SIADETOKEN })
  end

  def self.base_url
    'https://api-dev.apientreprise.fr'
  end
end
