# frozen_string_literal: true

# This task run over all exports to reload the columns and reserialize them using their current id
# In order to be refreshed, the column must be unserialized so the method find_column in ColumnConcern must be adapted to work with the old and new id format
# this task should be use with the task t20250115refreshColumnsIdInExportTask, t20250115refreshColumnsIdInExportTemplateTask, t20250115refreshColumnsIdInProcedurePresentationTask
module Maintenance
  class T20250115RefreshColumnsIdInExportTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern

    run_on_first_deploy

    def collection
      Export.all
    end

    def process(export)
      # by using the `will_change!` method, we ensure that the column will be saved
      # and thus the address and linked columns id will be migrated to the new format
      export.filtered_columns_will_change!
      export.sorted_column_will_change!

      export.save(validate: false)

    # a column can be not found for various reasons (deleted tdc, changed type, etc)
    # in this case we just ignore the error and continue
    rescue ActiveRecord::RecordNotFound
    end
  end
end
