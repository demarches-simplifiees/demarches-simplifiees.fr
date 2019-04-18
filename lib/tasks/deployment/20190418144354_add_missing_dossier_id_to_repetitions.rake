namespace :after_party do
  desc 'Deployment task: add_missing_dossier_id_to_repetitions'
  task add_missing_dossier_id_to_repetitions: :environment do
    puts "Running deploy task 'add_missing_dossier_id_to_repetitions'"

    champs = Champ.where(dossier_id: nil)
    progress = ProgressReport.new(champs.count)
    champs.find_each do |champ|
      champ.update_column(:dossier_id, champ.parent.dossier_id)
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20190418144354'
  end
end
