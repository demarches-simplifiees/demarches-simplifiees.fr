# frozen_string_literal: true

# This task run over all export_templates to reload the columns and reserialize them using their current id
# In order to be refreshed, the column must be unserialized so the method find_column in ColumnConcern must be adapted to work with the old and new id format
# this task should be use with the task t20250115refreshColumnsIdInExportTask, t20250115refreshColumnsIdInExportTemplateTask, t20250115refreshColumnsIdInProcedurePresentationTask
module Maintenance
  class T20250115RefreshColumnsIdInExportTemplateTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern

    run_on_first_deploy

    def collection
      ExportTemplate.all
    end

    def process(export_template)
      # by using the `will_change!` method, we ensure that the column will be saved
      # and thus the address and linked columns id will be migrated to the new format
      export_template.exported_columns_will_change!

      export_template.save(validate: false)
    end
  end
end
