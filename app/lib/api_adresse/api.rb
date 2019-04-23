class ApiAdresse::API
  def self.call(address, limit = 1)
    search_url = [API_ADRESSE_URL, "search"].join("/")

    RestClient::Request.execute(method: :get,
                                url: search_url,
                                timeout: 5,
                                headers: { params: { q: address, limit: limit } })
  rescue RestClient::ServiceUnavailable
    nil
  end
end
