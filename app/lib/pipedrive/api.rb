class Pipedrive::API
  def self.get(url, params)
    RestClient.get(url, params: params)
  end

  def self.put_deal(deal_id, params)
    url = PIPEDRIVE_DEALS_URL + "/#{deal_id}?api_token=#{PIPEDRIVE_TOKEN}"

    self.put(url, params)
  end

  def self.put_person(person_id, params)
    url = PIPEDRIVE_PEOPLE_URL + "/#{person_id}?api_token=#{PIPEDRIVE_TOKEN}"

    self.put(url, params)
  end

  private

  def self.put(url, params)
    RestClient.put(url, params.to_json, { content_type: :json })
  end
end
