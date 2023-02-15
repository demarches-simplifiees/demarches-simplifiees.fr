class TypesDeChamp::PrefillEpciTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def possible_values
    departements.map do |departement|
      "#{departement[:code]} (#{departement[:name]}) : https://geo.api.gouv.fr/epcis?codeDepartement=#{departement[:code]}"
    end
  end

  def example_value
    departement_code = departements.pick(:code)
    epci_code = APIGeoService.epcis(departement_code).pick(:code)
    [departement_code, epci_code]
  end

  def transform_value_to_assignable_attributes(value)
    return { code_departement: nil, value: nil } if value.blank? || !value.is_a?(Array)
    return { code_departement: value.first, value: nil } if value.one?
    { code_departement: value.first, value: value.second }
  end

  private

  def departements
    @departements ||= APIGeoService.departements.sort_by { |departement| departement[:code] }
  end
end
