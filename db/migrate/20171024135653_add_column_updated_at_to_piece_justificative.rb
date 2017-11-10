class AddColumnUpdatedAtToPieceJustificative < ActiveRecord::Migration[5.0]
  def change
    add_column :pieces_justificatives, :updated_at, :datetime
  end
end
