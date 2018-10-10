class CARTO::SGMAP::API
  def initialize
  end

  def self.search_qp(geojson)
    url = [API_CARTO_URL, "quartiers-prioritaires", "search"].join("/")
    call(url, { geojson: geojson.to_s })
  end

  def self.search_cadastre(geojson)
    url = [API_CARTO_URL, "cadastre", "geometrie"].join("/")
    call(url, { geojson: geojson.to_s })
  end

  def self.search_pa(geojson)
    url = [API_CARTO_URL, "parcelles-agricoles", "search"].join("/")
    call(url, { geojson: geojson.to_s })
  end

  private

  def self.call(url, params = {})
    verify_ssl_mode = OpenSSL::SSL::VERIFY_NONE

    RestClient::Resource.new(
      url,
      verify_ssl: verify_ssl_mode
    ).post params[:geojson], content_type: 'application/json'

  rescue RestClient::InternalServerError
    raise RestClient::ResourceNotFound
  end
end
