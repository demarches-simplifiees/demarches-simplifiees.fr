# frozen_string_literal: true

class EditableChamp::DropDownOtherInputComponent < EditableChamp::EditableChampBaseComponent
  def render?
    @champ.other?
  end
end
