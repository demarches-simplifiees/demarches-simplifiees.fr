namespace :after_party do
  desc 'Deployment task: update_missing_fields'
  task update_etablissements: :environment do
    puts "Running deploy task 'update_etablissements'"

    # Put your task implementation HERE.
    progress = ProgressReport.new(Dossier.count)
    Dossier.includes(procedure: [], etablissement: [:exercices]).find_each do |d|
      if d.etablissement.present?
        ApiEntrepriseService.create_etablissement(d, d.etablissement.siret)
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
