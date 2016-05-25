class AddOriginalFilenameToPiecesJustificatives < ActiveRecord::Migration
  def change
    add_column :pieces_justificatives, :original_filename, :string
  end
end
