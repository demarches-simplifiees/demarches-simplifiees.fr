# frozen_string_literal: true

module Maintenance
  class T20250527dropInvalideGeoAreasTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données geo area ne respectant pas le CRS WGS84.

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    def collection
      GeoArea.all
    end

    def process(element)
      element.validate
      if element.errors.where(:geometry, :invalid_geometry).any?
        element.delete
      end
    end

    def count
      # do not count, avoid timeout
    end
  end
end
