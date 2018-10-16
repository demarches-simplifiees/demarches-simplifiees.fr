module ApiAdresse
  # input : string (address)
  # output : json
  class Driver
    def initialize(address, limit = 1)
      @address = address
      @limit = limit
    end

    def call
      search_url = [API_ADRESSE_URL, "search"].join("/")

      RestClient.get(search_url, params: { q: @address, limit: @limit })
    rescue RestClient::ServiceUnavailable
      nil
    end
  end
end
