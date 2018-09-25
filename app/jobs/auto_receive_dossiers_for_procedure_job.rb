class AutoReceiveDossiersForProcedureJob < ApplicationJob
  queue_as :cron

  def perform(procedure_id, state)
    procedure = Procedure.find(procedure_id)
    case state
    when Dossier.states.fetch(:en_instruction)
      procedure.dossiers.state_en_construction.update_all(
        state: Dossier.states.fetch(:en_instruction),
        en_instruction_at: DateTime.now
      )
    when Dossier.states.fetch(:accepte)
      procedure.dossiers.state_en_construction.find_each do |dossier|
        dossier.update(
          state: Dossier.states.fetch(:accepte),
          en_instruction_at: DateTime.now,
          processed_at: DateTime.now
        )
        dossier.attestation = dossier.build_attestation
        dossier.save
        NotificationMailer.send_closed_notification(dossier).deliver_later
      end
    else
      raise "Receiving Procedure##{procedure_id} in invalid state \"#{state}\""
    end
  end
end
