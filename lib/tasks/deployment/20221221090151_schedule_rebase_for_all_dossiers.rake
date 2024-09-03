# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: schedule_rebase_for_all_dossiers'
  task schedule_rebase_for_all_dossiers: :environment do
    puts "Running deploy task 'schedule_rebase_for_all_dossiers'"

    dossiers = Dossier.joins(:procedure)
      .state_not_termine
      .state_not_brouillon
      .where('revision_id != procedures.published_revision_id')

    progress = ProgressReport.new(dossiers.count)

    dossiers.find_each do |dossier|
      dossier.rebase_later
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
