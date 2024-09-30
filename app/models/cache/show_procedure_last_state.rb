# frozen_string_literal: true

class Cache::ShowProcedureLastState
  attr_reader :procedure, :current_instructeur, :session

  def initialize(procedure:, current_instructeur:, session:)
    @procedure = procedure
    @current_instructeur = current_instructeur
    @session = session
  end

  def fetch_last_state
    Hash(session[cache_key(procedure:, current_instructeur:)])
  end

  def persist_last_state(params:)
    session[cache_key(procedure:, current_instructeur:)] = params.permit(:statut, :page).slice(:statut, :page).to_h
  end

  private

  def cache_key(procedure:, current_instructeur:)
    ["procedure_last_statut", procedure.id, current_instructeur.id].join('-')
  end
end
