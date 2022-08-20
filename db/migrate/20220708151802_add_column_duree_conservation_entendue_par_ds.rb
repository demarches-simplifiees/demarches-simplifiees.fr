class AddColumnDureeConservationEntendueParDs < ActiveRecord::Migration[6.1]
  def change
    add_column :procedures, :duree_conservation_etendue_par_ds, :boolean
  end
end
