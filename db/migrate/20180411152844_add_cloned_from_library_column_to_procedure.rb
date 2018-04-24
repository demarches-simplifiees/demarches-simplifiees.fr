class AddClonedFromLibraryColumnToProcedure < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :cloned_from_library, :boolean, default: false
  end
end
