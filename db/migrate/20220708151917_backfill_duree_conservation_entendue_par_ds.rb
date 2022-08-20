class BackfillDureeConservationEntendueParDs < ActiveRecord::Migration[6.1]
  def change
    Procedure.in_batches do |relation|
      relation.update_all duree_conservation_etendue_par_ds: true
      sleep(0.01)
    end
  end
end
