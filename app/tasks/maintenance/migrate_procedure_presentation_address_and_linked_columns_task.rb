# frozen_string_literal: true

module Maintenance
  class MigrateProcedurePresentationAddressAndLinkedColumnsTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern

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
