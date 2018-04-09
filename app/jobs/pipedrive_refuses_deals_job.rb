class PipedriveRefusesDealsJob < ApplicationJob
  def perform(person_id, owner_id)
    PipedriveService.refuse_demande_from_person(person_id, owner_id)
  end
end
