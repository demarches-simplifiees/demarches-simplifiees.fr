# frozen_string_literal: true

module Maintenance
  class T20250526NullifyRowIdTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données pour…

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      Dossier.all
    end

    def process(dossier)
      with_nil_row_id, with_null_row_id = dossier.champs
        .where(row_id: [nil, Champ::NULL_ROW_ID])
        .pluck(:row_id, :stream, :stable_id, :id, :updated_at)
        .partition { _1.first == nil }
        .map { _1.index_by { |(_, stream, stable_id)| [stream, stable_id] } }

      with_null_row_id.values.each do |(_, stream, stable_id, id, updated_at)|
        if with_nil_row_id[[stream, stable_id]].present?
          with_nil_updated_at, with_nil_id = with_nil_row_id[[stream, stable_id]].reverse
          if with_nil_updated_at > updated_at
            dossier.champs.where(id: id).destroy_all
          else
            dossier.champs.where(id: with_nil_id).destroy_all
            dossier.champs.where(id:).update_all(row_id: nil)
          end
        else
          dossier.champs.where(id:).update_all(row_id: nil)
        end
      end
    end

    def count
      with_statement_timeout("5min") do
        collection.count
      end
    end
  end
end
