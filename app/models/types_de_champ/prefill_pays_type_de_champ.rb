class TypesDeChamp::PrefillPaysTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def example_value
    countries.pick(:code)
  end

  private

  def possible_values_list
    countries.map { |country| "#{country[:code]} (#{country[:name]})" }
  end

  def countries
    @countries ||= APIGeoService.countries.sort_by { |country| country[:code] }
  end
end
