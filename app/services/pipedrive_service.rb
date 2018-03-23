class PipedriveService
  PIPEDRIVE_POSTE_ATTRIBUTE_ID = '33a790746f1713d712fe97bcce9ac1ca6374a4d6'

  PIPEDRIVE_ROBOT_ID = '2748449'
  PIPEDRIVE_CAMILLE_ID = '3189424'

  PIPEDRIVE_ALL_NOT_DELETED_DEALS = 'all_not_deleted'

  PIPEDRIVE_ADMIN_CENTRAL_STOCK_STAGE_ID = 35
  PIPEDRIVE_REGIONS_STOCK_STAGE_ID = 24
  PIPEDRIVE_PREFECTURES_STOCK_STAGE_ID = 20
  PIPEDRIVE_DEPARTEMENTS_STOCK_STAGE_ID = 30
  PIPEDRIVE_COMMUNES_STOCK_STAGE_ID = 40
  PIPEDRIVE_ORGANISMES_STOCK_STAGE_ID = 1

  class << self
    def accept_deals_from_person(person_id, owner_id, stage_id)
      waiting_deal_ids = fetch_waiting_deal_ids(person_id)
      waiting_deal_ids.each { |deal_id| update_deal_owner_and_stage(deal_id, owner_id, stage_id) }
      update_person_owner(person_id, owner_id)
    end

    def fetch_people_demandes
      params = {
        start: 0,
        limit: 500,
        user_id: PIPEDRIVE_ROBOT_ID,
        api_token: PIPEDRIVE_TOKEN
      }

      response = RestClient.get(PIPEDRIVE_PEOPLE_URL, { params: params })
      json = JSON.parse(response.body)

      json['data'].map do |datum|
        {
          person_id: datum['id'],
          nom: datum['name'],
          poste: datum[PIPEDRIVE_POSTE_ATTRIBUTE_ID],
          email: datum.dig('email', 0, 'value'),
          organisation: datum['org_name']
        }
      end
    end

    private

    def fetch_waiting_deal_ids(person_id)
      url = [PIPEDRIVE_PEOPLE_URL, person_id, "deals"].join('/')

      params = {
        start: 0,
        limit: 500,
        status: PIPEDRIVE_ALL_NOT_DELETED_DEALS,
        api_token: PIPEDRIVE_TOKEN
      }

      response = RestClient.get(url, params: params)
      json = JSON.parse(response.body)

      json['data'].map { |datum| datum['id'] }
    end

    def update_deal_owner_and_stage(deal_id, owner_id, stage_id)
      url = PIPEDRIVE_DEALS_URL + "/#{deal_id}?api_token=#{PIPEDRIVE_TOKEN}"

      params = { user_id: owner_id, stage_id: stage_id }

      RestClient.put(url, params.to_json, { content_type: :json })
    end

    def update_person_owner(person_id, owner_id)
      url = PIPEDRIVE_PEOPLE_URL + "/#{person_id}?api_token=#{PIPEDRIVE_TOKEN}"

      params = { owner_id: owner_id }

      RestClient.put(url, params.to_json, { content_type: :json })
    end
  end
end
