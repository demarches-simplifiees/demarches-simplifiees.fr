class AutoReceiveDossiersForProcedureJob < ApplicationJob
  queue_as :cron

  def perform(procedure_id, state)
    procedure = Procedure.find_by(id: procedure_id)
    if procedure
      procedure.dossiers.state_nouveaux.update_all(state: state, received_at: Time.now)
    end
  end
end
