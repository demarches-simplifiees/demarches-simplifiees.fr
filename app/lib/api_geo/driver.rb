module ApiGeo
  class Driver
    def self.regions
      url = [API_GEO_URL, "regions"].join("/")
      call(url)
    end

    def self.departements
      url = [API_GEO_URL, "departements"].join("/")
      call(url)
    end

    def self.pays
      File.open('app/lib/api_geo/pays.json').read
    end

    private

    def self.call(url)
      RestClient.get(url, params: { fields: :nom })
    rescue RestClient::ServiceUnavailable
      nil
    end
  end
end
