# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_backfill_procedure_routing_criteria_name'
  task fix_backfill_procedure_routing_criteria_name: :environment do
    puts "Running deploy task 'fix_backfill_procedure_routing_criteria_name'"

    # Put your task implementation HERE.
    procedure_without_routing_criteria_name = Procedure.with_discarded.where(routing_criteria_name: nil)
    progress = ProgressReport.new(procedure_without_routing_criteria_name.count)
    procedure_without_routing_criteria_name.in_batches do |relation|
      count = relation.count
      relation.update_all(routing_criteria_name: 'Votre ville')
      progress.inc(count)
    end
    progress.finish
    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
