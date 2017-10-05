class PocDeclaratoireJob < ApplicationJob
  queue_as :default

  def perform(procedure_id)
    procedure = Procedure.find(procedure_id)
    if procedure
      procedure.dossiers.state_nouveaux.update_all(state: "received", received_at: Time.now)
    end
  end
end
