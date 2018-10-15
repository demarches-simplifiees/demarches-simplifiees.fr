class ApiAdresse::API
  # input : string (address)
  # output : json
  def self.call(address, limit = 1)
    search_url = [API_ADRESSE_URL, "search"].join("/")

    RestClient.get(search_url, params: { q: address, limit: limit })
  rescue RestClient::ServiceUnavailable
    nil
  end
end
