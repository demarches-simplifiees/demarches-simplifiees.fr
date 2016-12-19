class CARTO::SGMAP::API
  def initialize
  end

  def self.search_qp(geojson)
    endpoint = "/quartiers-prioritaires/search"
    call(base_url + endpoint, {geojson: geojson.to_s})
  end

  def self.search_cadastre(geojson)
    endpoint = "/cadastre/geometrie"
    call(base_url + endpoint, {geojson: geojson.to_s})
  end

  private

  def self.call(url, params = {})
    verify_ssl_mode = OpenSSL::SSL::VERIFY_NONE

    RestClient::Resource.new(
        url,
        verify_ssl: verify_ssl_mode,
    ).post params[:geojson], content_type: 'application/json'
  end

  def self.base_url
    'https://apicarto.sgmap.fr'
  end
end
