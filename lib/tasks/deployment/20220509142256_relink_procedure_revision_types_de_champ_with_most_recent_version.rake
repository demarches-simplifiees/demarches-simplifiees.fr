namespace :after_party do
  desc 'Relink revision_types_de_champ repetition to current revision revision_types_de_champ'
  task relink_procedure_revision_types_de_champ_with_most_recent_version: :environment do
    puts "Running deploy task 'relink_procedure_revision_types_de_champ_with_most_recent_version'"

    # Put your task implementation HERE.
    Procedure.joins(:revisions).group('procedures.id').having("count(procedure_revisions.id) > 1").in_batches do |procedure|
      procedure.revisions.map(&:rebase_champs_repetable_parent_id)
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
