class RemoveArchivedFromProcedures < ActiveRecord::Migration[5.2]
  def change
    remove_column :procedures, :archived
  end
end
