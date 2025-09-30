# frozen_string_literal: true

class EditableChamp::RepetitionComponent < EditableChamp::EditableChampBaseComponent
  def legend_params
    @champ.description.present? ? { describedby: dom_id(@champ, :repetition) } : {}
  end

  def notice_params
    @champ.description.present? ? { id: dom_id(@champ, :repetition) } : {}
  end
end
