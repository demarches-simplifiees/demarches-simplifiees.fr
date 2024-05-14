# frozen_string_literal: true

class EditableChamp::ExplicationComponent < EditableChamp::EditableChampBaseComponent
  delegate :type_de_champ, to: :@champ
  delegate :notice_explicative, to: :type_de_champ
end
