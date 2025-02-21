# frozen_string_literal: true

module Maintenance
  class T20250221AddMissingStreamsTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données pour…

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    BATCH_SIZE = 100_000

    def collection
      rows_count = with_statement_timeout("5min") { Champs::RepetitionChamp.where(stream: nil).count }
      ((rows_count / BATCH_SIZE) + 1).times.to_a
    end

    def process(i)
      champ_ids = with_statement_timeout("5min") do
        Champs::RepetitionChamp.where(stream: nil).limit(BATCH_SIZE).offset(BATCH_SIZE * i).ids
      end
      with_statement_timeout("5min") { Champ.where(id: champ_ids).update_all(stream: 'main') }
    end
  end
end
