class Pipedrive::DealAdapter
  PIPEDRIVE_ADMIN_CENTRAL_STOCK_STAGE_ID = 35
  PIPEDRIVE_REGIONS_STOCK_STAGE_ID = 24
  PIPEDRIVE_PREFECTURES_STOCK_STAGE_ID = 20
  PIPEDRIVE_DEPARTEMENTS_STOCK_STAGE_ID = 30
  PIPEDRIVE_COMMUNES_STOCK_STAGE_ID = 40
  PIPEDRIVE_ORGANISMES_STOCK_STAGE_ID = 1
  PIPEDRIVE_ORGANISMES_REFUSES_STOCK_STAGE_ID = 45

  PIPEDRIVE_LOST_STATUS = "lost"
  PIPEDRIVE_LOST_REASON = "refusé depuis DS"

  PIPEDRIVE_CAMILLE_ID = '3189424'

  def self.refuse_deal(deal_id, owner_id)
    params = {
      user_id: owner_id,
      stage_id: PIPEDRIVE_ORGANISMES_REFUSES_STOCK_STAGE_ID,
      status: PIPEDRIVE_LOST_STATUS,
      lost_reason: PIPEDRIVE_LOST_REASON
    }

    Pipedrive::API.put_deal(deal_id, params)
  end

  def self.get_deals_ids_for_person(person_id)
    Pipedrive::API.get_deals_for_person(person_id)
      .map { |datum| datum['id'] }
  end

  def self.update_deal_owner_and_stage(deal_id, owner_id, stage_id)
    params = { user_id: owner_id, stage_id: stage_id }

    Pipedrive::API.put_deal(deal_id, params)
  end

  def self.add_deal(organisation_id, person_id, title)
    params = {
      org_id: organisation_id,
      person_id: person_id,
      title: title,
      user_id: Pipedrive::PersonAdapter::PIPEDRIVE_ROBOT_ID
    }

    Pipedrive::API.post_deal(params)
  end
end
