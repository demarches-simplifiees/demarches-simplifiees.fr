class AddOrderPlaceInTypeDePieceJustificative < ActiveRecord::Migration[5.2]
  def up
    add_column :types_de_piece_justificative, :order_place, :integer
  end

  def down
    remove_column :types_de_piece_justificative, :order_place
  end
end
