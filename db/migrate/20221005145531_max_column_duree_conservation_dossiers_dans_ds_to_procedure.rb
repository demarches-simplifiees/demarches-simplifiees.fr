# frozen_string_literal: true

class MaxColumnDureeConservationDossiersDansDsToProcedure < ActiveRecord::Migration[6.1]
  def change
    add_column :procedures, :max_duree_conservation_dossiers_dans_ds, :integer
    change_column_default :procedures, :max_duree_conservation_dossiers_dans_ds, Procedure::NEW_MAX_DUREE_CONSERVATION
  end
end
