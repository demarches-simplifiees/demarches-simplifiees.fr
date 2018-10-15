class ApiCarto::API
  def self.search_qp(geojson)
    url = [API_CARTO_URL, "quartiers-prioritaires", "search"].join("/")
    call(url, geojson)
  end

  def self.search_cadastre(geojson)
    url = [API_CARTO_URL, "cadastre", "geometrie"].join("/")
    call(url, geojson)
  end

  private

  def self.call(url, geojson)
    verify_ssl_mode = OpenSSL::SSL::VERIFY_NONE
    params = geojson.to_s

    client = RestClient::Resource.new(url, verify_ssl: verify_ssl_mode)
    client.post(params, content_type: 'application/json')

  rescue RestClient::InternalServerError
    raise RestClient::ResourceNotFound
  end
end
