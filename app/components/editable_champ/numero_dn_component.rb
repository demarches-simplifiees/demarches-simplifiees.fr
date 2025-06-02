# frozen_string_literal: true

class EditableChamp::NumeroDnComponent < EditableChamp::EditableChampBaseComponent
  def update_path
    champs_dn_path(@champ.dossier, @champ.stable_id, row_id: @champ.row_id)
  end
end
