class AddFormulaireIdToTypePieceJointe < ActiveRecord::Migration
  def change
    add_column :types_piece_jointe, :formulaire_id, :integer
  end
end
