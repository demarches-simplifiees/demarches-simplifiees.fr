class NewDefaultDureeConservationEntendueParDs < ActiveRecord::Migration[6.1]
  def change
    change_column_default :procedures, :duree_conservation_etendue_par_ds, false
  end
end
