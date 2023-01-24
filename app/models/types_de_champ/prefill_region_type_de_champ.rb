class TypesDeChamp::PrefillRegionTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def possible_values
    regions.map { |region| "#{region[:code]} (#{region[:name]})" }
  end

  private

  def regions
    @regions ||= APIGeoService.regions.sort_by { |region| region[:code] }
  end
end
