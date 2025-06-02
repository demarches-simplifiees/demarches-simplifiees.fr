# frozen_string_literal: true

class EditableChamp::COJOComponent < EditableChamp::EditableChampBaseComponent
  def input_group_class
    if @champ.accreditation_success?
      'fr-input-group--valid'
    elsif @champ.accreditation_error?
      'fr-input-group--error'
    end
  end
end
