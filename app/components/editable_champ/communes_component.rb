# frozen_string_literal: true

class EditableChamp::CommunesComponent < EditableChamp::EditableChampBaseComponent
  include ApplicationHelper

  def dsfr_input_classname
    'fr-select'
  end
end
