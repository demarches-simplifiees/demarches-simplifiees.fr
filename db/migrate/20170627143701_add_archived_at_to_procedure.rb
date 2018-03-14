class AddArchivedAtToProcedure < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :archived_at, :datetime
  end
end
