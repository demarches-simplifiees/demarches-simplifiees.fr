class AddCreatedAtToPieceJustificative < ActiveRecord::Migration[5.2]
  def change
    add_column :pieces_justificatives, :created_at, :datetime
  end
end
