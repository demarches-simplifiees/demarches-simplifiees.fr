# frozen_string_literal: true

class EditableChamp::TextareaComponent < EditableChamp::EditableChampBaseComponent
  include HtmlToStringHelper
  def dsfr_input_classname
    'fr-input'
    end
end
