module ChampHelper
  def has_label?(champ)
    types_without_label = [TypeDeChamp.type_champs.fetch(:header_section), TypeDeChamp.type_champs.fetch(:explication)]
    !types_without_label.include?(champ.type_champ)
  end

  def geo_data(champ)
    # rubocop:disable Rails/OutputSafety
    raw({
      position: champ.position,
      selection: champ.value.present? ? JSON.parse(champ.value) : [],
      quartiersPrioritaires: champ.quartiers_prioritaires? ? champ.quartiers_prioritaires : [],
      cadastres: champ.cadastres? ? champ.cadastres : [],
      parcellesAgricoles: champ.parcelles_agricoles? ? champ.parcelles_agricoles : []
    }.to_json)
    # rubocop:enable Rails/OutputSafety
  end
end
