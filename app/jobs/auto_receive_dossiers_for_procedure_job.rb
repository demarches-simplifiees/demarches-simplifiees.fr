class AutoReceiveDossiersForProcedureJob < ApplicationJob
  queue_as :cron

  def perform(procedure_id, state)
    procedure = Procedure.find(procedure_id)
    attrs = case state
    when 'en_instruction'
      {
        state: :en_instruction,
        en_instruction_at: DateTime.now
      }
    when 'accepte'
      {
        state: :accepte,
        en_instruction_at: DateTime.now,
        processed_at: DateTime.now
      }
    else
      raise "Receiving Procedure##{procedure_id} in invalid state \"#{state}\""
    end

    procedure.dossiers.state_en_construction.update_all(attrs)
  end
end
