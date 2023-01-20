class TypesDeChamp::PrefillDepartementTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def possible_values
    departements.map { |departement| "#{departement[:code]} (#{departement[:name]})" }
  end

  def example_value
    departements.pick(:code)
  end

  private

  def departements
    @departements ||= APIGeoService.departements.sort_by { |departement| departement[:code] }
  end
end
