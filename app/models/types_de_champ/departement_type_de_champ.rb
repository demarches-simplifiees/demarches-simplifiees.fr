class TypesDeChamp::DepartementTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def libelle_for_export(index)
    [libelle, "#{libelle} (Code)"][index]
  end

  def filter_to_human(filter_value)
    APIGeoService.departement_name(filter_value).presence || filter_value
  end
end
