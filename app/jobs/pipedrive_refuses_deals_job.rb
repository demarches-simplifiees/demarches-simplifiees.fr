class PipedriveRefusesDealsJob < ApplicationJob
  def perform(person_id, administration_id)
    PipedriveService.refuse_demande_from_person(person_id, administration_id)
  end
end
