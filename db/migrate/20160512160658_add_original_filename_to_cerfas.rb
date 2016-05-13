class AddOriginalFilenameToCerfas < ActiveRecord::Migration
  def change
    add_column :cerfas, :original_filename, :string
  end
end
