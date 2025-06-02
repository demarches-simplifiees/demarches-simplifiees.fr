# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: update_brouillon_dossiers_with_forced_groupe_instructeur'
  task update_brouillon_dossiers_with_forced_groupe_instructeur: :environment do
    puts "Running deploy task 'update_brouillon_dossiers_with_forced_groupe_instructeur'"

    # Put your task implementation HERE.
    dossiers_to_fix = Dossier.where(state: :brouillon).where(forced_groupe_instructeur: true).where(groupe_instructeur_id: nil)

    dossiers_to_fix.update_all(forced_groupe_instructeur: false)

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
