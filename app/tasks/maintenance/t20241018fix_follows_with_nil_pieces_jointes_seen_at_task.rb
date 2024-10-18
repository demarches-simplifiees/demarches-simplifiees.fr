# frozen_string_literal: true

module Maintenance
  class T20241018fixFollowsWithNilPiecesJointesSeenAtTask < MaintenanceTasks::Task
    # Normalement tous les follows auraient du être mis à jour lors de la migration db/migrate/20240911064340_backfill_follows_with_pieces_jointes_seen_at.rb
    # Mais, sur l'instance de DS, 57 follows créés lorsque la migration a tourné ont gardé une valeur nulle pour pieces_jointes_seen_at. On les met à jour ici.

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      # Collection to be iterated over
      # Must be Active Record Relation or Array
      Follow.where(pieces_jointes_seen_at: nil)
    end

    def process(element)
      # The work to be done in a single iteration of the task.
      # This should be idempotent, as the same element may be processed more
      # than once if the task is interrupted and resumed.
      element.update_columns(pieces_jointes_seen_at: Time.zone.now)
    end
  end
end
