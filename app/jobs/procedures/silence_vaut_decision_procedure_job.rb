class Procedures::SilenceVautDecisionProcedureJob < ApplicationJob
  queue_as :cron

  def perform
    now = DateTime.now

    procedures = Procedure.where(silence_vaut_decision_enabled: true)
    procedures.each do |p|
      attrs = case p.silence_vaut_decision_status
      when "accepte"
        {
          state: "accepte",
          processed_at: now
        }
      when "refuse"
        {
          state: "refuse",
          processed_at: now
        }
      end

      p.dossiers
        .where(state: "en_instruction")
        .where("en_instruction_at < ?", p.silence_vaut_decision_delais.days.ago)
        .update_all(attrs)
    end
  end
end
