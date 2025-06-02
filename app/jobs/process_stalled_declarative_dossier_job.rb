# frozen_string_literal: true

class ProcessStalledDeclarativeDossierJob < ApplicationJob
  def perform(dossier)
    return if dossier.declarative_triggered_at.present?

    case dossier.procedure.declarative_with_state
    when Procedure.declarative_with_states.fetch(:en_instruction)
      if !dossier.en_instruction? && dossier.may_passer_automatiquement_en_instruction?
        dossier.passer_automatiquement_en_instruction!
      end
    when Procedure.declarative_with_states.fetch(:accepte)
      if dossier.may_accepter_automatiquement?
        dossier.accepter_automatiquement!
      end
    end
  end

  def max_attempts
    3 # this job is enqueued by a cron, so it's better to not retry too much
  end
end
