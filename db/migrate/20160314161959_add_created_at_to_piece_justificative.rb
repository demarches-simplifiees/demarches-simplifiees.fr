class AddCreatedAtToPieceJustificative < ActiveRecord::Migration
  def change
    add_column :pieces_justificatives, :created_at, :datetime
  end
end
