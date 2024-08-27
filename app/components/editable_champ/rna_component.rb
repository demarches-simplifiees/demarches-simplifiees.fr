class EditableChamp::RNAComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_input_classname
    'fr-input'
  end

  def update_path
    if Champ.update_by_stable_id?
      champs_rna_path(@champ.dossier, @champ.stable_id, row_id: @champ.row_id)
    else
      champs_legacy_rna_path(@champ)
    end
  end
end
