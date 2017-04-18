class AddMandatoryColumnToTypesDePieceJustificative < ActiveRecord::Migration[5.0]
  def change
    add_column :types_de_piece_justificative, :mandatory, :boolean, default: false
  end
end
