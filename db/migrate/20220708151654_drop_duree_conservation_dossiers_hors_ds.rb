class DropDureeConservationDossiersHorsDs < ActiveRecord::Migration[6.1]
  def change
    safety_assured { remove_column :procedures, :duree_conservation_dossiers_hors_ds }
  end
end
