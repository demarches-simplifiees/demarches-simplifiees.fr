# frozen_string_literal: true

module Maintenance
  class MigrateExportTemplateAddressAndLinkedColumnsTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern

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
