class PipedriveRefusesDealsJob < ApplicationJob
  def perform(person_id, owner_id)
    PipedriveService.refuse_deals_from_person(person_id, owner_id)
  end
end
