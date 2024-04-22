class EditableChamp::CarteComponent < EditableChamp::EditableChampBaseComponent
  include ApplicationHelper
  def dsfr_champ_container
    :fieldset
  end

  def initialize(**args)
    super(**args)

    @autocomplete_component = EditableChamp::ComboSearchComponent.new(**args)
  end

  def update_path
    if Champ.update_by_stable_id?
      champs_carte_features_path(@champ.dossier, @champ.stable_id, row_id: @champ.row_id)
    else
      champs_legacy_carte_features_path(@champ)
    end
  end
end
