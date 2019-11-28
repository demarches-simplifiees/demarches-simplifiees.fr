namespace :after_party do
  desc 'Deployment task: archivee_to_close'
  task archivee_to_close: :environment do
    puts "Running deploy task 'archivee_to_close'"

    Procedure.where(aasm_state: :archivee).update_all(aasm_state: :close)
    Procedure.where(aasm_state: :close, closed_at: nil).find_each do |procedure|
      procedure.update_column(:closed_at, procedure.archived_at)
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20191114084623'
  end
end
