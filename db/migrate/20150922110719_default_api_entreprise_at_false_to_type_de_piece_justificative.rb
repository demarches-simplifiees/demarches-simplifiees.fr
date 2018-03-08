class DefaultAPIEntrepriseAtFalseToTypeDePieceJustificative < ActiveRecord::Migration[5.2]
  def change
    change_column :types_de_piece_justificative, :api_entreprise, :boolean, :default => false
  end
end
