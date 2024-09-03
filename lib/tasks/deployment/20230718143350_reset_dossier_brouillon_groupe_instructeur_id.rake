# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: reset_dossier_brouillon_groupe_instructeur_id'
  task reset_dossier_brouillon_groupe_instructeur_id: :environment do
    puts "Running deploy task 'reset_dossier_brouillon_groupe_instructeur_id'"

    dossier_brouillon = Dossier.state_brouillon.where.not(groupe_instructeur_id: nil)
    progress = ProgressReport.new(dossier_brouillon.count)

    # Put your task implementation HERE.
    dossier_brouillon.in_batches do |relation|
      progress.inc(relation.count)
      relation.update_all(groupe_instructeur_id: nil)
    end

    progress.finish
    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
