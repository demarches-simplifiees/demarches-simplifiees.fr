# frozen_string_literal: true

class EditableChamp::RNAComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_input_classname
    'fr-input'
  end

  def update_path
    champs_rna_path(@champ.dossier, @champ.stable_id, row_id: @champ.row_id)
  end
end
