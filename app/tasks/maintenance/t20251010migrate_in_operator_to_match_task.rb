# frozen_string_literal: true

module Maintenance
  class T20251010migrateInOperatorToMatchTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    FILTER_ATTRIBUTES = [
      :a_suivre_filters,
      :suivis_filters,
      :traites_filters,
      :tous_filters,
      :supprimes_filters,
      :supprimes_recemment_filters,
      :expirant_filters,
      :archives_filters,
    ].freeze

    def collection
      ProcedurePresentation.all
    end

    def process(procedure_presentation)
      updated = false

      FILTER_ATTRIBUTES.each do |attribute|
        current_filters = procedure_presentation.public_send(attribute)

        next if current_filters.blank?

        migrated_filters = current_filters.map do |filtered_column|
          migrate_in_to_match(filtered_column)
        end

        if migrated_filters != current_filters
          procedure_presentation.public_send("#{attribute}=", migrated_filters)
          updated = true
        end
      end

      procedure_presentation.save! if updated

    rescue ActiveRecord::RecordNotFound
      # a column can be not found for various reasons (deleted tdc, changed type, etc)
      # in this case we just ignore the error and continue
    end

    def migrate_in_to_match(filtered_column)
      filter = filtered_column.filter

      # Only migrate if the filter has an "in" operator
      if filter.is_a?(Hash) && filtered_column.filter_operator == 'in'
        migrated_filter = filter.merge(operator: 'match')
        FilteredColumn.new(column: filtered_column.column, filter: migrated_filter)
      else
        filtered_column
      end
    end
  end
end
