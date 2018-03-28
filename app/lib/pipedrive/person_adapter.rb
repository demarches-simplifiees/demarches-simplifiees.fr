class Pipedrive::PersonAdapter
  PIPEDRIVE_POSTE_ATTRIBUTE_ID = '33a790746f1713d712fe97bcce9ac1ca6374a4d6'
  PIPEDRIVE_ROBOT_ID = '2748449'

  def self.get_demandes_from_persons_owned_by_robot
    params = {
      start: 0,
      limit: 500,
      user_id: PIPEDRIVE_ROBOT_ID,
      api_token: PIPEDRIVE_TOKEN
    }

    response = Pipedrive::API.get(PIPEDRIVE_PEOPLE_URL, params)
    json_data = JSON.parse(response.body)['data']

    json_data.map do |datum|
      {
        person_id: datum['id'],
        nom: datum['name'],
        poste: datum[PIPEDRIVE_POSTE_ATTRIBUTE_ID],
        email: datum.dig('email', 0, 'value'),
        organisation: datum['org_name']
      }
    end
  end

  def self.update_person_owner(person_id, owner_id)
    params = { owner_id: owner_id }

    Pipedrive::API.put_person(person_id, params)
  end
end
