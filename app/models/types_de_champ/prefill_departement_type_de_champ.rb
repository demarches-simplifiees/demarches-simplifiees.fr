# frozen_string_literal: true

class TypesDeChamp::PrefillDepartementTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def all_possible_values
    departements.map { |departement| "#{departement[:code]} (#{departement[:name]})" }
  end

  private

  def departements
    @departements ||= APIGeoService.departements.sort_by { |departement| departement[:code] }
  end
end
