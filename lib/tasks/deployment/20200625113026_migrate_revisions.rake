# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: migrate_revisions'
  task migrate_revisions: :environment do
    puts "Running deploy task 'migrate_revisions'"

    if defined?(TmpDossiersMigrateRevisionsJob)
      procedures = Procedure.with_discarded.where(draft_revision_id: nil)
      progress = ProgressReport.new(procedures.count)

      puts "Processing procedures"

      procedures.find_each do |procedure|
        RevisionsMigration.add_revisions(procedure)
        progress.inc
      end

      progress.finish

      TmpDossiersMigrateRevisionsJob.perform_later([])
    else
      puts "Skip deploy task."
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20200625113026'
  end
end
