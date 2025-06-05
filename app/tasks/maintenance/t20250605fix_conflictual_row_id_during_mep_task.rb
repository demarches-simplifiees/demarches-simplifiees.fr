# frozen_string_literal: true

module Maintenance
  class T20250605fixConflictualRowIdDuringMepTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données pour…

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      Dossier.where("updated_at > ?", Date.new(2025, 6, 2))
    end

    def process(dossier)
      duplicated_champ_ids = dossier.champs.where(row_id: [Champ::NULL_ROW_ID, nil])
        .order(updated_at: :desc)
        .select(:id, :stream, :stable_id, :row_id)
        .group_by { "#{_1.stream}-#{_1.public_id}" }
        .values
        .flat_map { _1[1..].map(&:id) }
      Dossier.transaction do
        if duplicated_champ_ids.present?
          Dossier.no_touching { dossier.champs.where(id: duplicated_champ_ids).destroy_all }
        end
        dossier.champs.where(row_id: Champ::NULL_ROW_ID).update_all(row_id: nil)
      end
    end

    def count
      # Optionally, define the number of rows that will be iterated over
      # This is used to track the task's progress
    end
  end
end
