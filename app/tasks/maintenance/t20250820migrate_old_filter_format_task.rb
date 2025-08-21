# frozen_string_literal: true

module Maintenance
  class T20250820migrateOldFilterFormatTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données pour…

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    run_on_first_deploy

    def collection
      ProcedurePresentation.all
    end

    def process(element)
      [
        :a_suivre_filters,
        :suivis_filters,
        :traites_filters,
        :tous_filters,
        :supprimes_filters,
        :supprimes_recemment_filters,
        :expirant_filters,
        :archives_filters
      ].each do |filter_name|
        element.send("#{filter_name}=", element.send(filter_name.to_s).map do |filtered_column|
          normalize_filtered_column(filtered_column)
        end)

        element.save
      end
    end

    def normalize_filtered_column(filtered_column)
      FilteredColumn.new(
        column: filtered_column.column,
        filter: DossierFilterService.normalize_filter(filtered_column.filter)
      )
    end

    def count
      collection.count
    end
  end
end
