class PipedriveAcceptsDealsJob < ApplicationJob
  def perform(person_id, administration_id, stage_id)
    PipedriveService.accept_demande_from_person(person_id, administration_id, stage_id)
  end
end
