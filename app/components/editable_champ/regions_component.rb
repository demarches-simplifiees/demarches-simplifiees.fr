# frozen_string_literal: true

class EditableChamp::RegionsComponent < EditableChamp::EditableChampBaseComponent
  include ApplicationHelper

  def dsfr_input_classname
    'fr-select'
  end

  private

  def options
    @champ.options_for_select
  end

  def select_options
    { selected: @champ.selected }.merge(@champ.mandatory? ? { prompt: t('views.components.select_list') } : { include_blank: t('views.components.select_list') })
  end
end
