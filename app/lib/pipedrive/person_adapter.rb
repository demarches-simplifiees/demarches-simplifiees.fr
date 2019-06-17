class Pipedrive::PersonAdapter
  PIPEDRIVE_POSTE_ATTRIBUTE_ID = 'cb840cdb74daca5712749967fa7ecabe64bc58b6'
  PIPEDRIVE_SOURCE_ATTRIBUTE_ID = '7c0feb9a907c86165a88a98a757f144c3c64506a'
  PIPEDRIVE_NB_DOSSIERS_ATTRIBUTE_ID = '2734a3ff19f4b88bd0d7b4cf02c47c7545617207'
  PIPEDRIVE_DEADLINE_ATTRIBUTE_ID = 'ef766dd14de7da246fb5fc1704f45d1f1830f6c9'
  PIPEDRIVE_ROBOT_ID = '7945008'

  def self.get_demandes_from_persons_owned_by_robot
    Pipedrive::API.get_persons_owned_by_user(PIPEDRIVE_ROBOT_ID).map do |datum|
      {
        person_id: datum['id'],
        nom: datum['name'],
        poste: datum[PIPEDRIVE_POSTE_ATTRIBUTE_ID],
        email: datum.dig('email', 0, 'value'),
        tel: datum.dig('phone', 0, 'value'),
        organisation: datum['org_name'],
        nb_dossiers: datum[PIPEDRIVE_NB_DOSSIERS_ATTRIBUTE_ID],
        deadline: datum[PIPEDRIVE_DEADLINE_ATTRIBUTE_ID]
      }
    end
  end

  def self.update_person_owner(person_id, owner_id)
    params = { owner_id: owner_id }

    Pipedrive::API.put_person(person_id, params)
  end

  def self.add_person(email, phone, name, organization_id, poste, source, nb_of_dossiers, deadline)
    params = {
      email: email,
      phone: phone,
      name: name,
      org_id: organization_id,
      owner_id: PIPEDRIVE_ROBOT_ID,
      "#{PIPEDRIVE_POSTE_ATTRIBUTE_ID}": poste,
      "#{PIPEDRIVE_SOURCE_ATTRIBUTE_ID}": source,
      "#{PIPEDRIVE_NB_DOSSIERS_ATTRIBUTE_ID}": nb_of_dossiers,
      "#{PIPEDRIVE_DEADLINE_ATTRIBUTE_ID}": deadline
    }

    response = Pipedrive::API.post_person(params)

    JSON.parse(response.body)['data']['id']
  end
end
