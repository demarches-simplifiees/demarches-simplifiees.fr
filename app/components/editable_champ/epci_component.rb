class EditableChamp::EpciComponent < EditableChamp::EditableChampBaseComponent
  include ApplicationHelper

  private

  def departement_options
    APIGeoService.departements.filter { _1[:code] != '99' }.map { ["#{_1[:code]} – #{_1[:name]}", _1[:code]] }
  end

  def epci_options
    if @champ.departement?
      APIGeoService.epcis(@champ.code_departement).map { ["#{_1[:code]} – #{_1[:name]}", _1[:code]] }
    else
      []
    end
  end

  def departement_input_id
    "#{@champ.input_id}-departement"
  end

  def departement_select_options
    { selected: @champ.code_departement }.merge(@champ.mandatory? ? { prompt: '' } : { include_blank: '' })
  end

  def epci_select_options
    { selected: @champ.code }.merge(@champ.mandatory? ? { prompt: '' } : { include_blank: '' })
  end
end
