module Carto
  module Bano
    # input : string (address)
    # output : json
    class Driver
      def initialize(address)
        @address = address
      end

      def call
        RestClient.get api_url, params: { q: @address, limit: 1 }
      end

      def api_url
        'http://api-adresse.data.gouv.fr/search'
      end
    end
  end
end
