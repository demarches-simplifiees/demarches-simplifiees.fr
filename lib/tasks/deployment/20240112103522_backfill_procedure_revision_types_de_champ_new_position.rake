namespace :after_party do
  desc 'Deployment task: backfill_procedure_revision_types_de_champ_new_position'
  task backfill_procedure_revision_types_de_champ_new_position: :environment do
    puts "Running deploy task 'backfill_procedure_revision_types_de_champ_new_position'"

    # Put your task implementation HERE.
    ProcedureRevisionTypeDeChamp.in_batches.update_all(new_position: 'position')
    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
