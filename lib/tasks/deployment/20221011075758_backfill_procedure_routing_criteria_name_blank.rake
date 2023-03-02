namespace :after_party do
  desc 'Deployment task: backfill_procedure_routing_criteria_name_blank'
  task backfill_procedure_routing_criteria_name_blank: :environment do
    puts "Running deploy task 'backfill_procedure_routing_criteria_name_blank'"

    # Put your task implementation HERE.
    Procedure.pluck(:id, :routing_criteria_name)
      .filter { |_id, r| r.blank? }
      .map { |id, _r| Procedure.find(id).update(routing_criteria_name: 'Votre ville') }

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
