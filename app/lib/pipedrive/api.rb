class Pipedrive::API
  PIPEDRIVE_ALL_NOT_DELETED_DEALS = 'all_not_deleted'

  def self.get_persons_owned_by_user(user_id)
    params = {
      start: 0,
      limit: 500,
      user_id: user_id,
      api_token: PIPEDRIVE_TOKEN
    }

    self.get(PIPEDRIVE_PEOPLE_URL, params)
  end

  def self.get_deals_for_person(person_id)
    url = [PIPEDRIVE_PEOPLE_URL, person_id, "deals"].join('/')

    params = {
      start: 0,
      limit: 500,
      status: PIPEDRIVE_ALL_NOT_DELETED_DEALS,
      api_token: PIPEDRIVE_TOKEN
    }

    self.get(url, params)
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

  def self.get(url, params)
    RestClient.get(url, params: params)
  end

  def self.put(url, params)
    RestClient.put(url, params.to_json, { content_type: :json })
  end
end
