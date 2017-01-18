class AddLienToTypeDePieceJustificative < ActiveRecord::Migration[5.0]
  def change
    add_column :types_de_piece_justificative, :lien_demarche, :string, default: nil
  end
end
