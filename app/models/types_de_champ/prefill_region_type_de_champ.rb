class TypesDeChamp::PrefillRegionTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def possible_values
    regions.map { |region| "#{region[:code]} (#{region[:name]})" }
  end

  def example_value
    regions.pick(:code)
  end

  private

  def regions
    @regions ||= APIGeoService.regions.sort_by { |region| region[:code] }
  end
end
