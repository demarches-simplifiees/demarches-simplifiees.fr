# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: add_traitements_from_dossiers'
  task add_traitements_from_dossiers: :environment do
    puts "Running deploy task 'add_traitements_from_dossiers'"

    dossiers_termines = Dossier.state_termine
    progress = ProgressReport.new(dossiers_termines.count)
    dossiers_termines.find_each do |dossier|
      dossier.traitements.find_or_create_by!(state: dossier.state, motivation: dossier.motivation, processed_at: dossier.processed_at)
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20200630154829'
  end
end
