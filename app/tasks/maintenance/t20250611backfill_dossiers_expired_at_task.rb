# frozen_string_literal: true

module Maintenance
  class T20250611backfillDossiersExpiredAtTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données pour remplir
    # le nouvel attribut expired_at de la table dossiers.

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    def collection
      Dossier
        .where.not(state: Dossier.states.fetch(:en_instruction))
        .where(expired_at: nil)
    end

    def process(dossier)
      dossier.update_column(:expired_at, dossier.expiration_date)
    end
  end
end
