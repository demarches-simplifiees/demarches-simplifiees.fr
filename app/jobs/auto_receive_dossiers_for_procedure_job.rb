class AutoReceiveDossiersForProcedureJob < ApplicationJob
  queue_as :cron

  def perform(procedure_id, state)
    procedure = Procedure.find(procedure_id)
    attrs = case state
    when Dossier.states.fetch(:en_instruction)
      {
        state: Dossier.states.fetch(:en_instruction),
        en_instruction_at: DateTime.now
      }
    when Dossier.states.fetch(:accepte)
      {
        state: Dossier.states.fetch(:accepte),
        en_instruction_at: DateTime.now,
        processed_at: DateTime.now
      }
    else
      raise "Receiving Procedure##{procedure_id} in invalid state \"#{state}\""
    end

    procedure.dossiers.state_en_construction.update_all(attrs)
  end
end
