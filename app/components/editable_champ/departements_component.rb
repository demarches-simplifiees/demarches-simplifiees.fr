# frozen_string_literal: true

class EditableChamp::DepartementsComponent < EditableChamp::EditableChampBaseComponent
  include ApplicationHelper

  private

  def dsfr_input_classname
    'fr-select'
  end

  def options
    @champ.options_for_select
  end

  def select_options
    { selected: @champ.selected }.merge(@champ.mandatory? ? { prompt: '' } : { include_blank: '' })
  end
end
