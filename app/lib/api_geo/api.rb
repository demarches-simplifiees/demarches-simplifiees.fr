class ApiGeo::API
  TIMEOUT = 15
  CACHE_DURATION = 1.day

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
    # The cache engine is stored, because as of Typhoeus 1.3.1 the cache engine instance
    # is included in the computed `cache_key`.
    # (Which means that when the cache instance changes, the cache is invalidated.)
    @typhoeus_cache ||= Typhoeus::Cache::SuccessfulRequestsRailsCache.new

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
      }.merge(method == :post ? { 'Content-Type' => 'application/json' } : {}),
      cache: @typhoeus_cache,
      cache_ttl: CACHE_DURATION
    ).run

    if response.success?
      parse(response.body)
    else
      nil
    end
  end
end
