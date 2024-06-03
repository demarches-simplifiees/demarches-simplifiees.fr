class TypesDeChamp::RegionTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def filter_to_human(filter_value)
    APIGeoService.region_name(filter_value).presence || filter_value
  end

  private

  def paths
    paths = super
    paths.push({
      libelle: "#{libelle} (Code)",
      description: "#{description} (Code)",
      path: :code,
      maybe_null: public? && !mandatory?
    })
    paths
  end
end
