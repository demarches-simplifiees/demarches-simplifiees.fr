class RemoveArchivedFromProcedures < ActiveRecord::Migration[5.0]
  def change
    remove_column :procedures, :archived
  end
end
