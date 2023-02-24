class TypesDeChamp::PrefillCommuneTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def possible_values
    departements.map do |departement|
      "#{departement[:code]} (#{departement[:name]}) : https://geo.api.gouv.fr/communes?codeDepartement=#{departement[:code]}"
    end
  end

  def example_value
    departement_code = departements.pick(:code)
    commune_code = APIGeoService.communes(departement_code).pick(:code)
    [departement_code, commune_code]
  end

  def to_assignable_attributes(champ, value)
    return if value.blank? || !value.is_a?(Array)
    return if (departement_code = value.first).blank?
    return if (departement_name = APIGeoService.departement_name(departement_code)).blank?
    return if !value.one? && (commune_code = value.second).blank?
    return if !value.one? && (commune_name = APIGeoService.commune_name(departement_code, commune_code)).blank?

    if value.one?
      departement_attributes(champ, departement_code, departement_name)
    else
      departement_and_commune_attributes(champ, departement_code, departement_name, commune_code, commune_name)
    end
  end

  private

  def departement_attributes(champ, departement_code, departement_name)
    {
      id: champ.id,
      code_departement: departement_code,
      departement: departement_name
    }
  end

  def departement_and_commune_attributes(champ, departement_code, departement_name, commune_code, commune_name)
    postal_code = APIGeoService.commune_postal_codes(departement_code, commune_code).first

    departement_attributes(champ, departement_code, departement_name).merge(
      external_id: commune_code,
      value: "#{commune_name} (#{postal_code})"
    )
  end

  def departements
    @departements ||= APIGeoService.departements.sort_by { _1[:code] }
  end
end
