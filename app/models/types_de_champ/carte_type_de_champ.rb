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
end
