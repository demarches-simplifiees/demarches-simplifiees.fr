# frozen_string_literal: true

class TypesDeChamp::PrefillEpciTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def all_possible_values
    departements.map do |departement|
      "#{departement[:code]} (#{departement[:name]}) : https://geo.api.gouv.fr/epcis?codeDepartement=#{departement[:code]}"
    end
  end

  def example_value
    departement_code = departements.pick(:code)
    epci_code = APIGeoService.epcis(departement_code).pick(:code)
    [departement_code, epci_code]
  end

  def to_assignable_attributes(champ, value)
    return { id: champ.id, code_departement: nil, value: nil } if value.blank? || !value.is_a?(Array)
    return { id: champ.id, code_departement: value.first, value: nil } if value.one?
    { id: champ.id, code_departement: value.first, value: value.second }
  end

  private

  def departements
    @departements ||= APIGeoService.departements.sort_by { |departement| departement[:code] }
  end
end
