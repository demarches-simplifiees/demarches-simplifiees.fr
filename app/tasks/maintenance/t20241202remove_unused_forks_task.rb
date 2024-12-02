# frozen_string_literal: true

module Maintenance
  class T20241202removeUnusedForksTask < MaintenanceTasks::Task
    # Documentation: Cette tâche supprime les forks laissés après le passage en instruction

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    def collection
      Dossier.joins(:editing_fork_origin).where.not(editing_fork_origin: { state: 'en_construction' })
    end

    def process(dossier)
      dossier.destroy!
    end
  end
end
