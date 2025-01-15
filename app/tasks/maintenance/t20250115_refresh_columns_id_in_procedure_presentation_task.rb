# frozen_string_literal: true

# This task run over all procedure_presentations to reload the columns and reserialize them using their current id
# In order to be refreshed, the column must be unserialized so the method find_column in ColumnConcern must be adapted to work with the old and new id format
# this task should be use with the task t20250115refreshColumnsIdInExportTask, t20250115refreshColumnsIdInExportTemplateTask, t20250115refreshColumnsIdInProcedurePresentationTask
module Maintenance
  class T20250115RefreshColumnsIdInProcedurePresentationTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern

    run_on_first_deploy

    def collection
      ProcedurePresentation.all
    end

    def process(procedure_presentation)
      # by using the `will_change!` method, we ensure that the column will be saved
      # and thus the address and linked columns id will be migrated to the new format
      procedure_presentation.displayed_columns_will_change!
      procedure_presentation.sorted_column_will_change!
      procedure_presentation.a_suivre_filters_will_change!
      procedure_presentation.suivis_filters_will_change!
      procedure_presentation.traites_filters_will_change!
      procedure_presentation.tous_filters_will_change!
      procedure_presentation.supprimes_filters_will_change!
      procedure_presentation.supprimes_recemment_filters_will_change!
      procedure_presentation.expirant_filters_will_change!
      procedure_presentation.archives_filters_will_change!

      procedure_presentation.save(validate: false)
    end
  end
end
