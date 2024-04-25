# frozen_string_literal: true

module Maintenance
  class FixDureeConservationGreaterThanMaxDureeConservationTask < MaintenanceTasks::Task
    def collection
      Procedure.where('duree_conservation_dossiers_dans_ds > max_duree_conservation_dossiers_dans_ds')
    end

    def process(element)
      max_duree = element.max_duree_conservation_dossiers_dans_ds
      element.update!(duree_conservation_dossiers_dans_ds: max_duree)
    end

    def count
      # Optionally, define the number of rows that will be iterated over
      # This is used to track the task's progress
      collection.count
    end
  end
end
