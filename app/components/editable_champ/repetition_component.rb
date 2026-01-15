# frozen_string_literal: true

class EditableChamp::RepetitionComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_champ_container
    :fieldset
  end

  def legend_params
    @champ.description.present? ? { describedby: dom_id(@champ, :repetition) } : {}
  end

  def notice_params
    @champ.description.present? ? { id: dom_id(@champ, :repetition) } : {}
  end

  def show_toggle_all_button?
    @champ.dossier.revision.children_of(@champ.type_de_champ).size > 1
  end
end
