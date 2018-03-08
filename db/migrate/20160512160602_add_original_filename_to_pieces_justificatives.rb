class AddOriginalFilenameToPiecesJustificatives < ActiveRecord::Migration[5.2]
  def change
    add_column :pieces_justificatives, :original_filename, :string
  end
end
