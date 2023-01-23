class TypesDeChamp::PrefillPaysTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def possible_values
    countries.map { |country| "#{country[:code]} (#{country[:name]})" }
  end

  def example_value
    countries.pick(:code)
  end

  private

  def countries
    @countries ||= APIGeoService.countries.sort_by { |country| country[:code] }
  end
end
