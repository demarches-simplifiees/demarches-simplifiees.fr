# frozen_string_literal: true

module Maintenance
  class FixDecimalNumberWithSpacesTask < MaintenanceTasks::Task
    ANY_SPACES = /[[:space:]]/
    def collection
      Champs::DecimalNumberChamp.where.not(value: nil)
    end

    def process(element)
      if element.value.present? && ANY_SPACES.match?(element.value)
        element.update_column(:value, element.value.gsub(ANY_SPACES, ''))
      end
    end

    def count
      # not really interested in counting because it raises PG Statement timeout
    end
  end
end
