# frozen_string_literal: true

module Maintenance
  class T20260106FixMandatoryForPrivateAnnotationsTask < MaintenanceTasks::Task
    # Documentation: convert all current private annotation to non mandatory

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    run_on_first_deploy

    def collection
      TypeDeChamp.where(private: true, mandatory: true).in_batches
    end

    def process(batch)
      batch.update_all(mandatory: false)
    end
  end
end
