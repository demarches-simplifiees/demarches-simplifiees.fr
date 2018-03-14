class AddFormulaireIdToTypePieceJointe < ActiveRecord::Migration[5.2]
  def change
    add_column :types_piece_jointe, :formulaire_id, :integer
  end
end
