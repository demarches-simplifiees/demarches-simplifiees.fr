# frozen_string_literal: true

module Maintenance
  class T20251112backfillChampSiretExternalStateWithEtablissementButNoValueOrExternalIdTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données pour…

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      Champs::SiretChamp.in_batches
    end

    def process(batch)
      with_statement_timeout("5min") do
          errored_champs_from_batch = Champs::SiretChamp
            .where(
              id: batch.pluck(:id),
              value: nil,
              external_id: nil,
              external_state: :fetched
            )
          errored_champs_from_batch.each do |champ|
            champ.update_columns(
              value: champ.etablissement.siret,
              external_id: champ.etablissement.siret
            )
          end
        end
    end

    def count
      # noop
    end
  end
end
