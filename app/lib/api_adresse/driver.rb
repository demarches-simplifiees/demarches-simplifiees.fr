module ApiAdresse
  # input : string (address)
  # output : json
  class Driver
    def initialize(address, limit = 1)
      @address = address
      @limit = limit
    end

    def call
      RestClient.get api_url, params: { q: @address, limit: @limit }
    rescue RestClient::ServiceUnavailable
      nil
    end

    def api_url
      'http://api-adresse.data.gouv.fr/search'
    end
  end
end
