class AddRetentionTimesToProcedure < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :duree_conservation_dossiers_dans_ds, :integer
    add_column :procedures, :duree_conservation_dossiers_hors_ds, :integer
  end
end
