module ApiAdresse
  # input : string (address)
  # output : json
  class Driver
    def initialize(address, limit = 1)
      @address = address
      @limit = limit
    end

    def call
      RestClient.get(API_ADRESSE_URL, params: { q: @address, limit: @limit })
    rescue RestClient::ServiceUnavailable
      nil
    end
  end
end
