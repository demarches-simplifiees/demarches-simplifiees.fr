class EditableChamp::NumeroDnComponent < EditableChamp::EditableChampBaseComponent
  def update_path
    if Champ.update_by_stable_id?
      champs_dn_path(@champ.dossier, @champ.stable_id, row_id: @champ.row_id)
    else
      champs_legacy_dn_path(@champ)
    end
  end
end
