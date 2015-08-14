class RenameRefPieceJointToTypePieceJointe < ActiveRecord::Migration
  def change
    rename_table :ref_pieces_jointes, :types_piece_jointe
    rename_column :pieces_jointes, :ref_pieces_jointes_id, :type_piece_jointe_id
  end
end
