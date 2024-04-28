# frozen_string_literal: true

class EditableChamp::EmailComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_input_classname
    'fr-input'
  end

  def email?
    true
  end
end
