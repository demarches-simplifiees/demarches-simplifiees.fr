class ReBackfillProcedureMaxDureeConservationDossiers < ActiveRecord::Migration[6.1]
  def change
    Procedure.where(duree_conservation_etendue_par_ds: true).in_batches do |batch|
      batch.update_all(max_duree_conservation_dossiers_dans_ds: Procedure::OLD_MAX_DUREE_CONSERVATION)
    end
    Procedure.where(duree_conservation_etendue_par_ds: false).in_batches do |batch|
      batch.update_all(max_duree_conservation_dossiers_dans_ds: Procedure::NEW_MAX_DUREE_CONSERVATION)
    end
  end
end
