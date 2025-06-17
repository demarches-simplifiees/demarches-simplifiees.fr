# frozen_string_literal: true

class EditableChamp::CiviliteComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_champ_container
    :fieldset
  end

  def fieldset_legend_id
    "#{@champ.html_id}-label"
  end
end
