# frozen_string_literal: true

class Cache::ProcedureDossierPagination
  HALF_WINDOW = 50
  TRESHOLD_BEFORE_REFRESH = 1
  CACHE_EXPIRACY = 8.hours

  attr_reader :procedure_presentation, :statut, :cache
  delegate :procedure, :instructeur, to: :procedure_presentation

  def initialize(procedure_presentation:, statut:)
    @procedure_presentation = procedure_presentation
    @statut = statut
    @cache = Kredis.json(cache_key, expires_in: CACHE_EXPIRACY)
  end

  def save_context(ids:, incoming_page:)
    value = { ids: }
    value[:incoming_page] = incoming_page if incoming_page
    write_cache(value)
  end

  def next_dossier_id(from_id:)
    index = ids&.index(from_id.to_i)

    return nil if index.nil? # not found

    if refresh_cache_after?(from_id:)
      renew_ids(from_id:)
      index = ids.index(from_id.to_i)
    end
    return nil if index.blank?
    return nil if index + 1 > ids.size # out of bound end

    ids[index + 1]
  end

  def previous_dossier_id(from_id:)
    index = ids&.index(from_id.to_i)

    return nil if index.nil? # not found

    if refresh_cache_before?(from_id:)
      renew_ids(from_id:)
      index = ids.index(from_id.to_i)
    end
    return nil if index.blank?
    return nil if index - 1 < 0 # out of bound start

    ids[index - 1]
  end

  def incoming_page
    read_cache[:incoming_page]
  end

  private

  def cache_key
    [procedure.id, instructeur.id, statut].join(":")
  end

  def write_cache(value)
    cache.value = value
    @read_cache = nil
  end

  def read_cache
    @read_cache ||= Hash(cache.value).with_indifferent_access
  end

  def ids = read_cache[:ids]

  def refresh_cache_after?(from_id:) = from_id.in?(ids.last(TRESHOLD_BEFORE_REFRESH))

  def refresh_cache_before?(from_id:) = from_id.in?(ids.first(TRESHOLD_BEFORE_REFRESH))

  def renew_ids(from_id:)
    value = read_cache
    ids_around = fetch_ids_around(from_id:)

    # if ids_around is empty, it means that the current dossier was not found in all fetch ids (it can have changed status)
    # we do not want to refresh the cache in this case, it would break navigation
    return if ids_around.empty?

    value[:ids] = ids_around

    write_cache(value)
  end

  def fetch_all_ids
    dossiers = Dossier.where(groupe_instructeur_id: GroupeInstructeur.joins(:instructeurs, :procedure).where(procedure: procedure, instructeurs: [instructeur]).select(:id))
    DossierFilterService.filtered_sorted_ids(dossiers, statut, procedure_presentation.filters_for(statut), procedure_presentation.sorted_column, instructeur, count: 0)
  end

  def fetch_ids_around(from_id:)
    all_ids = fetch_all_ids
    from_id_at = all_ids.index(from_id)

    if from_id_at.present?
      new_page_starts_at = [0, from_id_at - HALF_WINDOW].max # avoid index below 0
      new_page_ends_at = [from_id_at + HALF_WINDOW, all_ids.size].min # avoid index above all_ids.size
      all_ids.slice(new_page_starts_at, new_page_ends_at)
    else
      []
    end
  end
end
