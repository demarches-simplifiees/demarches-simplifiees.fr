class EditableChamp::CommunesComponent < EditableChamp::EditableChampBaseComponent
  include ApplicationHelper

  private

  def commune_options
    @champ.communes.map { ["#{_1[:name]} (#{_1[:postal_code]})", _1[:code]] }
  end

  def code_postal_input_id
    "#{@champ.input_id}-code_postal"
  end

  def commune_select_options
    { selected: @champ.selected }.merge(@champ.mandatory? ? { prompt: '' } : { include_blank: '' })
  end
end
