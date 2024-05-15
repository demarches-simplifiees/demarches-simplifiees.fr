class EditableChamp::SiretComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_input_classname
    'fr-input'
  end

  def hint_id
    dom_id(@champ, :siret_info)
  end

  def hintable?
    true
  end

  def update_path
    if Champ.update_by_stable_id?
      champs_siret_path(@champ.dossier, @champ.stable_id, row_id: @champ.row_id)
    else
      champs_legacy_siret_path(@champ)
    end
  end
end
