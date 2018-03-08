class RenamePieceJointeToPieceJustificatives < ActiveRecord::Migration[5.2]
  def change
    rename_table :pieces_jointes, :pieces_justificatives
  end
end
