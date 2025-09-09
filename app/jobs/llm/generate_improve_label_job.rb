# frozen_string_literal: true

class LLM::GenerateImproveLabelJob < ApplicationJob
  queue_as :default

  def perform(procedure_id)
    procedure = Procedure
      .includes(published_revision: :revision_types_de_champ_public)
      .find_by(id: procedure_id)
    return if procedure.nil? || procedure.published_revision.nil?

    Rails.logger.info("[LLM] improve_label generation enqueued for procedure=#{procedure.id}")

    # Integration with the future service will happen here (generate + verify + persist).
    # This job intentionally no-ops until the service and persistence are introduced.
  end
end
