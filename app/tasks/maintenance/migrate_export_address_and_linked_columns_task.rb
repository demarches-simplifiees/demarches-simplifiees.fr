# frozen_string_literal: true

module Maintenance
  class MigrateExportAddressAndLinkedColumnsTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern

    def collection
      Export.all
    end

    def process(export)
      # by using the `will_change!` method, we ensure that the column will be saved
      # and thus the address and linked columns id will be migrated to the new format
      export.filtered_columns_will_change!
      export.sorted_column_will_change!

      export.save(validate: false)
    end
  end
end
