class AddJuridiqueRequiredColumnToProcedure < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :juridique_required, :boolean, default: true
  end
end
