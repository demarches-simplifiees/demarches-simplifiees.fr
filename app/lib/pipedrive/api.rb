class Pipedrive::API
  PIPEDRIVE_ALL_NOT_DELETED_DEALS = 'all_not_deleted'
  PIPEDRIVE_DEALS_URL = [PIPEDRIVE_API_URL, 'deals'].join("/")
  PIPEDRIVE_PEOPLE_URL = [PIPEDRIVE_API_URL, 'persons'].join("/")
  PIPEDRIVE_ORGANIZATIONS_URL = [PIPEDRIVE_API_URL, 'organizations'].join("/")

  def self.get_persons_owned_by_user(user_id)
    url = PIPEDRIVE_PEOPLE_URL
    params = { user_id: user_id }

    self.get(url, params)
  end

  def self.get_deals_for_person(person_id)
    url = [PIPEDRIVE_PEOPLE_URL, person_id, "deals"].join('/')
    params = { status: PIPEDRIVE_ALL_NOT_DELETED_DEALS }

    self.get(url, params)
  end

  def self.put_deal(deal_id, params)
    url = [PIPEDRIVE_DEALS_URL, deal_id].join("/")

    self.put(url, params)
  end

  def self.post_deal(params)
    self.post(PIPEDRIVE_DEALS_URL, params)
  end

  def self.put_person(person_id, params)
    url = [PIPEDRIVE_PEOPLE_URL, person_id].join("/")

    self.put(url, params)
  end

  def self.post_person(params)
    self.post(PIPEDRIVE_PEOPLE_URL, params)
  end

  def self.post_organization(params)
    self.post(PIPEDRIVE_ORGANIZATIONS_URL, params)
  end

  private

  def self.get(url, params)
    params.merge!({
      start: 0,
      limit: 500,
      api_token: token
    })

    response = Typhoeus.get(url, params: params)

    if response.success?
      JSON.parse(response.body)['data']
    end
  end

  def self.put(url, params)
    Typhoeus.put(
      url,
      params: { api_token: token },
      body: params.to_json,
      headers: { 'content-type' => 'application/json' }
    )
  end

  def self.post(url, params)
    Typhoeus.post(
      url,
      params: { api_token: token },
      body: params.to_json,
      headers: { 'content-type' => 'application/json' }
    )
  end

  def self.token
    Rails.application.secrets.pipedrive[:key]
  end
end
