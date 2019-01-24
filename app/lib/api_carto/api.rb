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
    params = geojson.to_s
    RestClient.post(url, params, content_type: 'application/json')

  rescue RestClient::InternalServerError => e
    Rails.logger.error "[ApiCarto] Error on #{url}: #{e}"
    raise RestClient::ResourceNotFound
  end
end
