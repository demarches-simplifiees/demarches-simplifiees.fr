class Pipedrive::OrganizationAdapter
  def self.add_organization(name, address)
    params = {
      name: name,
      owner_id: Pipedrive::PersonAdapter::PIPEDRIVE_ROBOT_ID,
      address: address
    }

    response = Pipedrive::API.post_organization(params)

    JSON.parse(response.body)['data']['id']
  end
end
