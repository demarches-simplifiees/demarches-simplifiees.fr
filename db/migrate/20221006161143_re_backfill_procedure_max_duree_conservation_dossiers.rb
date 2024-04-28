# frozen_string_literal: true

class ReBackfillProcedureMaxDureeConservationDossiers < ActiveRecord::Migration[6.1]
  def change
    Procedure.with_discarded.where(duree_conservation_etendue_par_ds: true).in_batches do |batch|
      batch.update_all(max_duree_conservation_dossiers_dans_ds: Procedure::OLD_MAX_DUREE_CONSERVATION)
    end
    Procedure.with_discarded.where(duree_conservation_etendue_par_ds: false).in_batches do |batch|
      batch.update_all(max_duree_conservation_dossiers_dans_ds: Procedure::NEW_MAX_DUREE_CONSERVATION)
    end
    Procedure.with_discarded.where(duree_conservation_etendue_par_ds: nil).in_batches do |batch|
      batch.update_all(
        duree_conservation_etendue_par_ds: false,
        max_duree_conservation_dossiers_dans_ds: Procedure::NEW_MAX_DUREE_CONSERVATION
      )
    end
  end
end
