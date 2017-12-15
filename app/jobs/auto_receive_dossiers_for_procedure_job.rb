class AutoReceiveDossiersForProcedureJob < ApplicationJob
  queue_as :cron

  def perform(procedure_id, state)
    procedure = Procedure.find_by(id: procedure_id)
    if procedure
      procedure.dossiers.state_en_construction.update_all(state: state, en_instruction_at: Time.now)
    end
  end
end
