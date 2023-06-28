class TypesDeChamp::RegionTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def libelle_for_export(index)
    [libelle, "#{libelle} (Code)"][index]
  end

  def filter_to_human(filter_value)
    APIGeoService.region_name(filter_value).presence || filter_value
  end
end
