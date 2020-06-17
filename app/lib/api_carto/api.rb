class ApiCarto::API
  class ResourceNotFound < StandardError
  end

  def self.search_cadastre(geojson)
    url = [API_CARTO_URL, "cadastre", "geometrie"].join("/")
    call(url, geojson)
  end

  private

  def self.call(url, geojson)
    response = Typhoeus.post(url, body: geojson.to_s, headers: { 'content-type' => 'application/json' })

    if response.success?
      response.body
    else
      message = response.code == 0 ? response.return_message : response.code.to_s
      Rails.logger.error "[ApiCarto] Error on #{url}: #{message}"
      raise ResourceNotFound
    end
  end
end
