# frozen_string_literal: true

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

  def tags_for_template = [].freeze

  def champ_value_for_api(champ, version: 2)
    nil
  end

  def champ_value_for_export(champ, path = :value)
    champ.geo_areas.map(&:label).join("\n")
  end

  def champ_value_blank?(champ)
    champ.geo_areas.blank?
  end
end
