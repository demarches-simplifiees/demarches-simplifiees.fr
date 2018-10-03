class Pipedrive::DealAdapter
  PIPEDRIVE_ADMIN_CENTRAL_STOCK_STAGE_ID = 35
  PIPEDRIVE_SERVICE_DECO_REGIONAL_STOCK_STAGE_ID = 24
  PIPEDRIVE_SERVICE_DECO_DEPARTEMENTAL_STOCK_STAGE_ID = 20
  PIPEDRIVE_COLLECTIVITE_DEP_OU_REG_STOCK_STAGE_ID = 30
  PIPEDRIVE_COLLECTIVITE_LOCALE_STOCK_STAGE_ID = 40
  PIPEDRIVE_ORGANISMES_STOCK_STAGE_ID = 1
  PIPEDRIVE_ORGANISMES_REFUSES_STOCK_STAGE_ID = 45
  PIPEDRIVE_SUSPECTS_COMPTE_CREE_STAGE_ID = 48

  PIPEDRIVE_LOST_STATUS = "lost"
  PIPEDRIVE_LOST_REASON = "refusé depuis DS"

  PIPEDRIVE_NB_OF_PROCEDURES_ATTRIBUTE_ID = "b22f8710352a7fb548623c062bf82ed6d1b6b704"
  PIPEDRIVE_NB_OF_PROCEDURES_DO_NOT_KNOW_VALUE = "Je ne sais pas"
  PIPEDRIVE_NB_OF_PROCEDURES_1_VALUE = "juste 1"
  PIPEDRIVE_NB_OF_PROCEDURES_1_TO_10_VALUE = "de 1 a 10"
  PIPEDRIVE_NB_OF_PROCEDURES_10_TO_100_VALUE = "de 10 a 100"
  PIPEDRIVE_NB_OF_PROCEDURES_ABOVE_100_VALUE = "Plus de 100"

  PIPEDRIVE_DEADLINE_ATTRIBUTE_ID = "36a72c82af9d9f0d476b041ede8876844a249bf2"
  PIPEDRIVE_DEADLINE_ASAP_VALUE = "Le plus vite possible"
  PIPEDRIVE_DEADLINE_NEXT_3_MONTHS_VALUE = "Dans les 3 prochain mois"
  PIPEDRIVE_DEADLINE_NEXT_6_MONTHS_VALUE = "Dans les 6 prochain mois"
  PIPEDRIVE_DEADLINE_NEXT_12_MONTHS_VALUE = "Dans les 12 prochain mois"
  PIPEDRIVE_DEADLINE_NO_DATE_VALUE = "Pas de date"

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
    deals = Pipedrive::API.get_deals_for_person(person_id) || []
    deals.map { |datum| datum['id'] }
  end

  def self.update_deal_owner_and_stage(deal_id, owner_id, stage_id)
    params = { user_id: owner_id, stage_id: stage_id }

    Pipedrive::API.put_deal(deal_id, params)
  end

  def self.add_deal(organisation_id, person_id, title, nb_of_procedures, nb_of_dossiers, deadline)
    params = {
      org_id: organisation_id,
      person_id: person_id,
      title: title,
      user_id: Pipedrive::PersonAdapter::PIPEDRIVE_ROBOT_ID,
      "#{PIPEDRIVE_NB_OF_PROCEDURES_ATTRIBUTE_ID}": nb_of_procedures,
      value: nb_of_dossiers,
      "#{PIPEDRIVE_DEADLINE_ATTRIBUTE_ID}": deadline
    }

    Pipedrive::API.post_deal(params)
  end
end
