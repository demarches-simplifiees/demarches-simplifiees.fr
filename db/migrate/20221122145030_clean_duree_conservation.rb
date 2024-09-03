# frozen_string_literal: true

class CleanDureeConservation < ActiveRecord::Migration[6.1]
  def change
    # We ignore strong_migrations safety warnings, because these table is relatively small
    safety_assured do
      change_column_null :procedures, :duree_conservation_etendue_par_ds, false
      change_column_null :procedures, :max_duree_conservation_dossiers_dans_ds, false
    end
  end
end
