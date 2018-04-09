class PipedriveService
  def self.accept_demande_from_person(person_id, owner_id, stage_id)
    person_deals_ids = Pipedrive::DealAdapter.get_deals_ids_for_person(person_id)
    person_deals_ids.each { |deal_id| Pipedrive::DealAdapter.update_deal_owner_and_stage(deal_id, owner_id, stage_id) }
    Pipedrive::PersonAdapter.update_person_owner(person_id, owner_id)
  end

  def self.refuse_demande_from_person(person_id, owner_id)
    person_deals_ids = Pipedrive::DealAdapter.get_deals_ids_for_person(person_id)
    person_deals_ids.each { |deal_id| Pipedrive::DealAdapter.refuse_deal(deal_id, owner_id) }
    Pipedrive::PersonAdapter.update_person_owner(person_id, owner_id)
  end

  def self.get_demandes
    Pipedrive::PersonAdapter.get_demandes_from_persons_owned_by_robot
  end
end
