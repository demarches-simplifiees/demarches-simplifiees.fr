class AddExpectsMultipleSubmissionsColumnToProcedure < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :expects_multiple_submissions, :boolean, default: false, null: false
  end
end
