class PipedriveService
  def self.accept_demande_from_person(person_id, administration_id, stage_id)
    owner_id = BizDev.pipedrive_id(administration_id)
    person_deals_ids = Pipedrive::DealAdapter.get_deals_ids_for_person(person_id)
    person_deals_ids.each { |deal_id| Pipedrive::DealAdapter.update_deal_owner_and_stage(deal_id, owner_id, stage_id) }
    Pipedrive::PersonAdapter.update_person_owner(person_id, owner_id)
  end

  def self.refuse_demande_from_person(person_id, administration_id)
    owner_id = BizDev.pipedrive_id(administration_id)
    person_deals_ids = Pipedrive::DealAdapter.get_deals_ids_for_person(person_id)
    person_deals_ids.each { |deal_id| Pipedrive::DealAdapter.refuse_deal(deal_id, owner_id) }
    Pipedrive::PersonAdapter.update_person_owner(person_id, owner_id)
  end

  def self.get_demandes
    Pipedrive::PersonAdapter.get_demandes_from_persons_owned_by_robot
  end

  def self.add_demande(email, phone, name, poste, source, organization_name, address, nb_of_procedures, nb_of_dossiers, deadline)
    organization_id = Pipedrive::OrganizationAdapter.add_organization(organization_name, address)
    person_id = Pipedrive::PersonAdapter.add_person(email, phone, name, organization_id, poste, source, nb_of_dossiers, deadline)
    Pipedrive::DealAdapter.add_deal(organization_id, person_id, organization_name, nb_of_procedures, nb_of_dossiers, deadline)
  end
end
