class AddProcedureIdIndexToTypesDePieceJustificative < ActiveRecord::Migration[5.2]
  def change
    add_index :types_de_piece_justificative, :procedure_id
  end
end
