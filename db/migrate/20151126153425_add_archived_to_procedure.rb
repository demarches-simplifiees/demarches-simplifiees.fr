class AddArchivedToProcedure < ActiveRecord::Migration
  def change
    add_column :procedures, :archived, :boolean, default: false
  end
end
