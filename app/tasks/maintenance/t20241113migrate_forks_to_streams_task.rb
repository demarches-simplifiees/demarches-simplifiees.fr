# frozen_string_literal: true

module Maintenance
  class T20241113migrateForksToStreamsTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données pour…

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    def collection
      Dossier.joins(:editing_fork_origin).where(editing_fork_origin: { state: 'en_construction' })
    end

    def process(fork)
      DossierPreloader.load_one(fork)
      dossier_en_construction = fork.editing_fork_origin
      dossier_en_construction.rebase!
      dossier_en_construction.reload
      DossierPreloader.load_one(dossier_en_construction)
      diff = dossier_en_construction.make_diff(fork)
      dossier_en_construction.send(:with_stream, Champ::USER_BUFFER_STREAM)
      dossier_en_construction.transaction do
        dossier_en_construction.send(:apply_diff, diff)
        fork.reload
        fork.destroy!
      end
    end
  end
end
