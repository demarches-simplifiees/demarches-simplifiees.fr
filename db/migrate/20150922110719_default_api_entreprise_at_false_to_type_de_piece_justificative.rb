class DefaultAPIEntrepriseAtFalseToTypeDePieceJustificative < ActiveRecord::Migration
  def change
    change_column :types_de_piece_justificative, :api_entreprise, :boolean, :default => false
  end
end
