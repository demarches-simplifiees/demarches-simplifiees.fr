class TypesDeChamp::PrefillRegionTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def possible_values_list
    regions.map { |region| "#{region[:code]} (#{region[:name]})" }
  end

  private

  def regions
    @regions ||= APIGeoService.regions.sort_by { |region| region[:code] }
  end
end
