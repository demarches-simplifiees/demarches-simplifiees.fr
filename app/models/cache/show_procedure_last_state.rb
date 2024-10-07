# frozen_string_literal: true

class Cache::ShowProcedureLastState
  PAGE_SIZE = 100
  TRESHOLD_BEFORE_REFRECH = 5

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
    session[cache_key(procedure:, current_instructeur:)] = params.merge(filtered_sorted_paginated_ids:)
  end

  def next_dossier_id(from_id:)
    index = paginated_ids.index(from_id.to_i)

    return nil if index.nil? # not found

    if refresh_cache_after?(from_id:)
      renew_paginated_ids(from_id:)
      index = paginated_ids.index(from_id.to_i)
    end

    return nil if paginated_ids.size < index + 1 # out of bound end

    paginated_ids[index + 1]
  end

  def previous_dossier_id(from_id:)
    index = paginated_ids.index(from_id.to_i)

    return nil if index.nil? # not found

    if refresh_cache_before?(from_id:)
      renew_paginated_ids(from_id:)
      index = paginated_ids.index(from_id.to_i)
    end

    return nil if index - 1 < 0 # out of bound start

    paginated_ids[index - 1]
  end

  private

  def refresh_cache_after?(from_id:)
    from_id.in?(paginated_ids.last(TRESHOLD_BEFORE_REFRECH))
  end

  def refresh_cache_before?(from_id:)
    from_id.in?(paginated_ids.first(TRESHOLD_BEFORE_REFRECH))
  end

  def renew_paginated_ids(from_id:)
    all_ids = fetch_all_paginated_ids
    new_page = extract_page(from_id:, all_ids:)

    session[cache_key(procedure:, current_instructeur:)][:filtered_sorted_paginated_ids] = new_page
    @cache = session[cache_key(procedure:, current_instructeur:)]
  end

  def fetch_all_paginated_ids
    groupe_instructeur_ids = current_instructeur
      .assign_to
      .joins(:groupe_instructeur)
      .where(groupe_instructeur: { procedure_id: procedure.id })
      .map(&:groupe_instructeur_id)
    dossiers = Dossier.where(groupe_instructeur_id: groupe_instructeur_ids)
    procedure_presentation.filtered_sorted_ids(dossiers, statut)
  end

  def procedure_presentation
    procedure_presentation, _ = current_instructeur.procedure_presentation_and_errors_for_procedure_id(procedure.id)
    procedure_presentation
  end

  def extract_page(from_id:, all_ids:)
    index_at = all_ids.index(from_id)
    start_at = [0, index_at - (PAGE_SIZE - TRESHOLD_BEFORE_REFRECH) / 2].max
    end_at = [all_ids.size, index_at + (PAGE_SIZE - TRESHOLD_BEFORE_REFRECH) / 2].min

    all_ids[start_at..end_at]
  end

  def statut
    fetch_last_state[:statut]
  end

  def cache # reader, don't want to override things without directly acceding the session
    @cache ||= begin
      h = session[cache_key(procedure:, current_instructeur:)]
      h ||= {}
      h.with_indifferent_access
    end
  end

  def paginated_ids
    cache[:filtered_sorted_paginated_ids]
  end

  def cache_key(procedure:, current_instructeur:)
    ["procedure_last_statut", procedure.id, current_instructeur.id].join('-')
  end
end
