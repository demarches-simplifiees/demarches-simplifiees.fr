class AutoReceiveDossiersForProcedureJob < ApplicationJob
  queue_as :cron

  def perform(procedure_id, state)
    procedure = Procedure.find(procedure_id)
    case state
    when Dossier.states.fetch(:en_instruction)
      procedure.dossiers.state_en_construction.update_all(
        state: Dossier.states.fetch(:en_instruction),
        en_instruction_at: Time.zone.now
      )
    when Dossier.states.fetch(:accepte)
      procedure.dossiers.state_en_construction.find_each do |dossier|
        dossier.change_state_with_motivation(:accepte, '')
      end
    else
      raise "Receiving Procedure##{procedure_id} in invalid state \"#{state}\""
    end
  end
end
