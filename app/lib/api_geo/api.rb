class ApiGeo::API
  TIMEOUT = 15

  def self.regions
    url = [API_GEO_URL, "regions"].join("/")
    call(url, { fields: :nom })
  end

  def self.departements
    url = [API_GEO_URL, "departements"].join("/")
    call(url, { fields: :nom })
  end

  def self.pays
    parse(File.open('app/lib/api_geo/pays.json').read)
  end

  def self.search_rpg(geojson)
    url = [API_GEO_SANDBOX_URL, "rpg", "parcelles", "search"].join("/")
    call(url, geojson, :post)
  end

  private

  def self.parse(body)
    JSON.parse(body, symbolize_names: true)
  end

  def self.call(url, body, method = :get)
    response = Typhoeus::Request.new(
      url,
      method: method,
      params: method == :get ? body : nil,
      body: method == :post ? body : nil,
      timeout: TIMEOUT,
      accept_encoding: 'gzip',
      headers: {
        'Accept' => 'application/json',
        'Accept-Encoding' => 'gzip, deflate'
      }.merge(method == :post ? { 'Content-Type' => 'application/json' } : {})
    ).run

    if response.success?
      parse(response.body)
    else
      nil
    end
  end
end
