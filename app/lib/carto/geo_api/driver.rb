module Carto
  module GeoAPI
    class Driver
      def self.regions
        url = [API_GEO_URL, "regions"].join("/")
        call url
      end

      def self.departements
        url = [API_GEO_URL, "departements"].join("/")
        call url
      end

      def self.pays
        File.open('app/lib/carto/geo_api/pays.json').read
      end

      private

      def self.call(api_url)
        RestClient.get api_url, params: { fields: :nom }
      rescue RestClient::ServiceUnavailable
        nil
      end
    end
  end
end
