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
      # Use raw SQL with UPDATE ... FROM to reference joined table safely
      conn = ApplicationRecord.connection

      sql = <<~SQL.squish
        UPDATE champs
        SET value = etablissements.siret,
            external_id = etablissements.siret
        FROM etablissements
        WHERE champs.etablissement_id = etablissements.id
          AND champs.id IN (#{batch.ids.join(',')})
          AND champs.value IS NULL
          AND champs.external_id IS NULL
          AND champs.external_state = '#{Champs::SiretChamp.external_states[:fetched]}'
          AND champs.type = 'Champs::SiretChamp'
      SQL
      conn.execute(sql)
    end

    def count
      # noop
    end
  end
end
