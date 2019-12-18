class ApiCarto::API
  def self.search_qp(geojson)
    url = [API_CARTO_URL, "quartiers-prioritaires", "search"].join("/")
    call(url, geojson)
  end

  def self.search_cadastre(geojson)
    url = [API_CARTO_URL, "cadastre", "parcelle"].join("/")
    call(url, geojson)
  end

  private

  def self.call(url, geojson)
    response = Typhoeus.get(url, params: { geom: geojson.to_s }, headers: { 'content-type' => 'application/json' })

    if response.success?
      response.body
    else
      Rails.logger.error "[ApiCarto] Error on #{url}. Code #{response.code}, #{response.body}"
      raise RestClient::ResourceNotFound
    end
  end
end
