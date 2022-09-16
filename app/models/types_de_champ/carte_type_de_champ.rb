class TypesDeChamp::CarteTypeDeChamp < TypesDeChamp::TypeDeChampBase
  LAYERS = [
    :unesco,
    :arretes_protection,
    :conservatoire_littoral,
    :reserves_chasse_faune_sauvage,
    :reserves_biologiques,
    :reserves_naturelles,
    :natura_2000,
    :zones_humides,
    :znieff,
    :cadastres
  ]

  def estimated_fill_duration(revision)
    FILL_DURATION_LONG
  end

  def libelle_for_export(index)
    ["Carte (Label)", "Carte (GeoJSON)"][index]
  end
end
