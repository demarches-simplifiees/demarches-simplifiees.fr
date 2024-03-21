class EditableChamp::AddressComponent < EditableChamp::EditableChampBaseComponent
  def pays_options
    APIGeoService.countries.map { [_1[:name], _1[:code]] }
  end

  def input_disabled?
    @champ.ban? || @champ.international?
  end

  def input_disabled_unless_international?
    @champ.ban?
  end

  def filled?
    @champ.international? || !@champ.ban? || @champ.code_departement?
  end
end
