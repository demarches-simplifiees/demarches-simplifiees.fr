# frozen_string_literal: true

class EditableChamp::RegionsComponent < EditableChamp::EditableChampBaseComponent
  include ApplicationHelper

  def dsfr_input_classname
    'fr-select'
  end

  private

  def options
    APIGeoService.regions.map { [_1[:name], _1[:code]] }
  end

  def select_options
    { selected: @champ.selected }.merge(@champ.mandatory? ? { prompt: '' } : { include_blank: '' })
  end
end
