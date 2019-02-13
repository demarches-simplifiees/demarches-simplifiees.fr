namespace :after_party do
  desc 'Deployment task: fix_macedonia'
  task fix_macedonia: :environment do
    puts "Running deploy task 'fix_macedonia'"

    # Put your task implementation HERE.

    Champ.where(type: "Champs::PaysChamp", value: "EX-REPUBLIQUE YOUGOSLAVE DE MACEDOINE").update_all(value: "MACEDOINE DU NORD (REPUBLIQUE DE)")

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20190212164238'
  end # task :fix_macedonia
end # namespace :after_party
