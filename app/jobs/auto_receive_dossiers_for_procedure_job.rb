class AutoReceiveDossiersForProcedureJob < ApplicationJob
  queue_as :cron

  def perform(procedure_id, state)
    procedure = Procedure.find(procedure_id)

    case state
    when Dossier.states.fetch(:en_instruction)
      procedure
        .dossiers
        .state_en_construction
        .find_each(&:passer_automatiquement_en_instruction!)
    when Dossier.states.fetch(:accepte)
      procedure
        .dossiers
        .state_en_construction
        .find_each(&:accepter_automatiquement!)
    else
      raise "Receiving Procedure##{procedure_id} in invalid state \"#{state}\""
    end
  end
end
