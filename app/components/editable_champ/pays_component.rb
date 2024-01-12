class EditableChamp::PaysComponent < EditableChamp::EditableChampBaseComponent
  include ApplicationHelper

  def dsfr_input_classname
    'fr-select'
  end

  private

  def options
    options = APIGeoService.countries.map { [_1[:name], _1[:code]] }
    # For legacy fields, selected value is non standard country name. Add it to the list.
    if (@champ.selected&.size || 0) > 2
      options.unshift([@champ.selected, @champ.selected])
    end
    options
  end

  def select_options
    { selected: @champ.selected }.merge(@champ.mandatory? ? { prompt: '' } : { include_blank: '' })
  end
end
