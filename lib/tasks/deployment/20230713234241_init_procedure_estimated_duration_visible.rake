# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: init_procedure_estimated_duration_visible'
  task init_procedure_estimated_duration_visible: :environment do
    puts "Running deploy task 'init_procedure_estimated_duration_visible'"

    Procedure.with_discarded.in_batches do |relation|
      relation.update_all estimated_duration_visible: true
      sleep(0.01)
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
