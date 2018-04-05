class PipedriveService
  class << self
    def accept_deals_from_person(person_id, owner_id, stage_id)
      waiting_deal_ids = Pipedrive::DealAdapter.fetch_waiting_deal_ids(person_id)
      waiting_deal_ids.each { |deal_id| Pipedrive::DealAdapter.update_deal_owner_and_stage(deal_id, owner_id, stage_id) }
      Pipedrive::PersonAdapter.update_person_owner(person_id, owner_id)
    end

    def refuse_deals_from_person(person_id, owner_id)
      waiting_deal_ids = Pipedrive::DealAdapter.fetch_waiting_deal_ids(person_id)
      waiting_deal_ids.each { |deal_id| Pipedrive::DealAdapter.refuse_deal(deal_id, owner_id) }
      Pipedrive::PersonAdapter.update_person_owner(person_id, owner_id)
    end

    def get_demandes
      Pipedrive::PersonAdapter.get_demandes_from_persons_owned_by_robot
    end
  end
end
