# frozen_string_literal: true

class TypesDeChamp::PrefillPaysTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def all_possible_values
    countries.map { |country| "#{country[:code]} (#{country[:name]})" }
  end

  private

  def countries
    @countries ||= APIGeoService.countries.sort_by { |country| country[:code] }
  end
end
