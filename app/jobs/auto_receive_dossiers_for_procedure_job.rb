class AutoReceiveDossiersForProcedureJob < ApplicationJob
  queue_as :cron

  def perform(procedure_id, state, gestionnaire_id = nil)
    procedure = Procedure.find(procedure_id)
    gestionnaire = procedure.gestionnaire_for_cron_job

    case state
    when Dossier.states.fetch(:en_instruction)
      procedure.dossiers.state_en_construction.find_each do |dossier|
        dossier.passer_en_instruction!(gestionnaire)
      end
    when Dossier.states.fetch(:accepte)
      procedure.dossiers.state_en_construction.find_each do |dossier|
        dossier.accepter!('')
      end
    else
      raise "Receiving Procedure##{procedure_id} in invalid state \"#{state}\""
    end
  end
end
