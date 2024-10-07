# frozen_string_literal: true

class Cache::ShowProcedureLastState
  attr_reader :procedure, :current_instructeur, :session

  def initialize(procedure:, current_instructeur:, session:)
    @procedure = procedure
    @current_instructeur = current_instructeur
    @session = session
  end

  def fetch_last_state
    cache.slice(:page, :statut)
  end

  def raw
    cache
  end

  def persist_last_state(params:, filtered_sorted_paginated_ids:)
    session[cache_key(procedure:, current_instructeur:)] = params.permit(:statut, :page).slice(:statut, :page).to_h.merge(filtered_sorted_paginated_ids:)
  end

  private

  def cache # reader, don't want to override things without directly acceding the session
    @cache ||= begin
      h = session[cache_key(procedure:, current_instructeur:)]
      h ||= {}
      h.with_indifferent_access
    end
  end

  def cache_key(procedure:, current_instructeur:)
    ["procedure_last_statut", procedure.id, current_instructeur.id].join('-')
  end
end
