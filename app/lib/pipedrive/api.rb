class Pipedrive::API
  def self.put(url, params)
    RestClient.put(url, params, { content_type: :json })
  end

  def self.get(url, params)
    RestClient.get(url, params: params)
  end
end
