# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: set_dossiers_processed_at'
  task set_dossiers_processed_at: :environment do
    puts "Running deploy task 'set_dossiers_processed_at'"

    dossiers = Dossier.with_discarded.state_termine.includes(:traitement)
    progress = ProgressReport.new(dossiers.count)

    dossiers.find_each do |dossier|
      if dossier.read_attribute(:processed_at) != dossier.traitement.processed_at
        dossier.update_column(:processed_at, dossier.traitement.processed_at)
      end
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
