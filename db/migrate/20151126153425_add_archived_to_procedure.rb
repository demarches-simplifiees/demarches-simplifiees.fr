class AddArchivedToProcedure < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :archived, :boolean, default: false
  end
end
