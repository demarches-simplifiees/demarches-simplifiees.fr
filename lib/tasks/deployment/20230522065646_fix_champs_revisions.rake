namespace :after_party do
  desc 'Deployment task: fix_champs_revisions'
  task fix_champs_revisions: :environment do
    puts "Running deploy task 'fix_champs_revisions'"

    progress = ProgressReport.new(Dossier.count)

    fixer = Recovery::AlignChampWithDossierRevision.new(Dossier, progress:)
    fixer.run
    fixer.logs.each do |log|
      puts JSON.dump(log)
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
