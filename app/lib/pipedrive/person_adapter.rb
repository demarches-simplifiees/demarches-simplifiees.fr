class Pipedrive::PersonAdapter
  PIPEDRIVE_POSTE_ATTRIBUTE_ID = 'cb840cdb74daca5712749967fa7ecabe64bc58b6'
  PIPEDRIVE_SOURCE_ATTRIBUTE_ID = '7c0feb9a907c86165a88a98a757f144c3c64506a'
  PIPEDRIVE_ROBOT_ID = '7945008'

  def self.get_demandes_from_persons_owned_by_robot
    Pipedrive::API.get_persons_owned_by_user(PIPEDRIVE_ROBOT_ID).map do |datum|
      {
        person_id: datum['id'],
        nom: datum['name'],
        poste: datum[PIPEDRIVE_POSTE_ATTRIBUTE_ID],
        email: datum.dig('email', 0, 'value'),
        tel: datum.dig('phone', 0, 'value'),
        organisation: datum['org_name']
      }
    end
  end

  def self.update_person_owner(person_id, owner_id)
    params = { owner_id: owner_id }

    Pipedrive::API.put_person(person_id, params)
  end

  def self.add_person(email, phone, name, organization_id, poste, source)
    params = {
      email: email,
      phone: phone,
      name: name,
      org_id: organization_id,
      owner_id: PIPEDRIVE_ROBOT_ID,
      "#{PIPEDRIVE_POSTE_ATTRIBUTE_ID}": poste,
      "#{PIPEDRIVE_SOURCE_ATTRIBUTE_ID}": source
    }

    response = Pipedrive::API.post_person(params)

    JSON.parse(response.body)['data']['id']
  end
end
