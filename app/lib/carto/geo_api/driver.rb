module Carto
  module GeoAPI
    class Driver
      def self.regions
        call regions_url
      end

      def self.departements
        call departements_url
      end

      def self.pays
        File.open('app/lib/carto/geo_api/pays.json').read
      end

      def self.departements_url
        'https://geo.api.gouv.fr/departements'
      end

      def self.regions_url
        'https://geo.api.gouv.fr/regions'
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
