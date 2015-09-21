class RenamePieceJointeToPieceJustificatives < ActiveRecord::Migration
  def change
    rename_table :pieces_jointes, :pieces_justificatives
  end
end
