# frozen_string_literal: true

module Maintenance
  # PR: 10774
  # why: postgres does not support integer greater than FilteredColumn::PG_INTEGER_MAX_VALUE)
  #      it occures when user copypaste the dossier id twice (like missed copy paste,paste)
  #      once this huge integer is saved on procedure presentation, page with this filter can't be loaded
  # when: run this migration when it appears in your maintenance tasks list, this file fix the data and we added some validations too
  class CleanInvalidProcedurePresentationTask < MaintenanceTasks::Task
    def collection
      ProcedurePresentation.all
    end

    def process(element)
      element.filters = element.filters.transform_values do |filters_by_status|
        filters_by_status.reject do |filter|
          filter.is_a?(Hash) &&
          filter['column'] == 'id' &&
          (filter['value']&.to_i&. >= FilteredColumn::PG_INTEGER_MAX_VALUE)
        end
      end
      element.save
    end

    def count
      # Optionally, define the number of rows that will be iterated over
      # This is used to track the task's progress
    end
  end
end
