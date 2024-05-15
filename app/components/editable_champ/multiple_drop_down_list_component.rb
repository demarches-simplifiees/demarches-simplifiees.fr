class EditableChamp::MultipleDropDownListComponent < EditableChamp::EditableChampBaseComponent
  include ApplicationHelper

  def dsfr_input_classname
    'fr-select'
  end

  def dsfr_champ_container
    @champ.render_as_checkboxes? ? :fieldset : :div
  end

  def update_path(option)
    if Champ.update_by_stable_id?
      champs_options_path(@champ.dossier, @champ.stable_id, row_id: @champ.row_id, option:)
    else
      champs_legacy_options_path(@champ, option:)
    end
  end
end
