class RemoveExpectsMultipleSubmissionsFromProcedure < ActiveRecord::Migration[5.2]
  def change
    remove_column :procedures, :expects_multiple_submissions, :boolean, default: false, null: false
  end
end
