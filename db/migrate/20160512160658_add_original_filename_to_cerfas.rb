class AddOriginalFilenameToCerfas < ActiveRecord::Migration[5.2]
  def change
    add_column :cerfas, :original_filename, :string
  end
end
