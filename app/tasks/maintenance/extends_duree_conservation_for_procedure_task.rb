# frozen_string_literal: true

module Maintenance
  class ExtendsDureeConservationForProcedureTask < MaintenanceTasks::Task
    csv_collection

    def process(element)
      procedure_id = element["procedure_id"]
      dossier_conservation_extension = Integer(element["dossier_conservation_extension"])
      procedure_duree_conservation = Integer(element["procedure_duree_conservation_dossiers_dans_ds"])

      Dossier.joins(:procedure)
        .where(procedure: { id: procedure_id })
        .find_each do |dossier|
        dossier.extend_conservation(dossier_conservation_extension.months)
      end
      Procedure.where(id: procedure_id)
        .update_all(duree_conservation_dossiers_dans_ds: procedure_duree_conservation,
                           duree_conservation_etendue_par_ds: true)
    end
  end
end
