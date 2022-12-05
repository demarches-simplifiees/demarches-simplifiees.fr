class AddPieceJustificativeMultipleOnProcedures < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      # Only new procedures will have multiple enabled by default
      add_column :procedures, :piece_justificative_multiple, :boolean, default: false, null: false
      change_column_default :procedures, :piece_justificative_multiple, from: false, to: true
    end
  end
end
